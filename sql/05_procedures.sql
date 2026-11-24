-- =====================================================================
-- EcoCircuito - Script 05: stored procedures (com transações)
-- Cada procedure faz tudo ou nada: se algo falhar, ROLLBACK.
-- =====================================================================
USE ecocircuito;

DELIMITER $$

-- ---------------------------------------------------------------------
-- 1) Registrar entrega com vários itens de uma vez
--    p_itens em JSON: [{"categoria":1,"descricao":"Notebook","peso":2.4}, ...]
--    p_data: NULL = agora (usado com data só para carga de dados de teste)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_registrar_entrega(
  IN  p_id_gerador INT UNSIGNED,
  IN  p_id_ponto   INT UNSIGNED,
  IN  p_itens      JSON,
  IN  p_data       DATETIME,
  OUT p_id_entrega INT UNSIGNED
)
BEGIN
  DECLARE v_gerador_ok   INT DEFAULT 0;
  DECLARE v_ponto_ok     INT DEFAULT 0;
  DECLARE v_capacidade   DECIMAL(10,2);
  DECLARE v_estoque      DECIMAL(12,2);
  DECLARE v_peso_novo    DECIMAL(12,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_gerador_ok
    FROM gerador WHERE id_gerador = p_id_gerador AND ativo = TRUE;
  IF v_gerador_ok = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gerador inexistente ou inativo.';
  END IF;

  -- trava a linha do ponto para duas entregas simultâneas não estourarem a capacidade
  SELECT COUNT(*), MAX(capacidade_kg) INTO v_ponto_ok, v_capacidade
    FROM ponto_coleta WHERE id_ponto = p_id_ponto AND ativo = TRUE
    FOR UPDATE;
  IF v_ponto_ok = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ponto de coleta inexistente ou inativo.';
  END IF;

  IF p_itens IS NULL OR JSON_LENGTH(p_itens) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A entrega precisa ter pelo menos um item.';
  END IF;

  -- capacidade: o que já está parado no ponto + o que está chegando
  SELECT COALESCE(SUM(i.peso_kg), 0) INTO v_estoque
    FROM item_residuo i
    JOIN entrega e ON e.id_entrega = i.id_entrega
   WHERE e.id_ponto = p_id_ponto AND i.status = 'RECEBIDO';

  SELECT COALESCE(SUM(peso), 0) INTO v_peso_novo
    FROM JSON_TABLE(p_itens, '$[*]' COLUMNS (peso DECIMAL(8,2) PATH '$.peso')) j;

  IF v_estoque + v_peso_novo > v_capacidade THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Capacidade do ponto de coleta excedida. Envie um lote antes.';
  END IF;

  INSERT INTO entrega (id_gerador, id_ponto, data_entrega)
  VALUES (p_id_gerador, p_id_ponto, COALESCE(p_data, NOW()));

  SET p_id_entrega = LAST_INSERT_ID();

  -- o código de rastreio é gerado pela trigger trg_item_gera_codigo
  INSERT INTO item_residuo (id_entrega, id_categoria, descricao, peso_kg)
  SELECT p_id_entrega, j.categoria, j.descricao, j.peso
    FROM JSON_TABLE(p_itens, '$[*]' COLUMNS (
           categoria INT UNSIGNED  PATH '$.categoria',
           descricao VARCHAR(120)  PATH '$.descricao',
           peso      DECIMAL(8,2)  PATH '$.peso')) j;

  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- 2) Fechar e enviar um lote: pega todos os itens RECEBIDOS do ponto
--    e manda para o reciclador (a trigger valida a licença)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_enviar_lote(
  IN  p_id_ponto      INT UNSIGNED,
  IN  p_id_reciclador INT UNSIGNED,
  IN  p_data          DATETIME,
  OUT p_id_lote       INT UNSIGNED
)
BEGIN
  DECLARE v_qtd INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  -- trava os itens que vão entrar no lote
  SELECT COUNT(*) INTO v_qtd
    FROM item_residuo i
    JOIN entrega e ON e.id_entrega = i.id_entrega
   WHERE e.id_ponto = p_id_ponto AND i.status = 'RECEBIDO'
     FOR UPDATE;

  IF v_qtd = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não há itens aguardando envio neste ponto.';
  END IF;

  INSERT INTO lote (id_ponto, id_reciclador, data_envio)
  VALUES (p_id_ponto, p_id_reciclador, COALESCE(p_data, NOW()));

  SET p_id_lote = LAST_INSERT_ID();

  UPDATE item_residuo i
    JOIN entrega e ON e.id_entrega = i.id_entrega
     SET i.id_lote = p_id_lote,
         i.status  = 'ENVIADO'
   WHERE e.id_ponto = p_id_ponto AND i.status = 'RECEBIDO';

  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- 3) Processar o lote no reciclador:
--    calcula os materiais recuperados, marca itens como RECICLADO,
--    fecha o lote e emite o certificado de destinação
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_processar_lote(
  IN p_id_lote INT UNSIGNED,
  IN p_data    DATETIME
)
BEGIN
  DECLARE v_status VARCHAR(10);
  DECLARE v_data   DATETIME;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET v_data = COALESCE(p_data, NOW());

  START TRANSACTION;

  SELECT status INTO v_status FROM lote WHERE id_lote = p_id_lote FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote não encontrado.';
  END IF;
  IF v_status <> 'ENVIADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote já foi processado.';
  END IF;

  -- peso recuperado por material = peso do item x % do material na categoria
  INSERT INTO recuperacao (id_lote, id_material, peso_kg)
  SELECT p_id_lote, c.id_material, SUM(i.peso_kg * c.percentual / 100)
    FROM item_residuo i
    JOIN composicao_categoria c ON c.id_categoria = i.id_categoria
   WHERE i.id_lote = p_id_lote AND i.status = 'ENVIADO'
   GROUP BY c.id_material;

  UPDATE item_residuo
     SET status = 'RECICLADO'
   WHERE id_lote = p_id_lote AND status = 'ENVIADO';

  UPDATE lote
     SET status = 'PROCESSADO', data_processamento = v_data
   WHERE id_lote = p_id_lote;

  INSERT INTO certificado_destinacao (id_lote, codigo, data_emissao)
  VALUES (p_id_lote,
          CONCAT('CDF-', YEAR(v_data), '-', LPAD(p_id_lote, 6, '0')),
          v_data);

  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- 4) Rejeitar um item na triagem (ex.: chegou contaminado ou não é eletrônico)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_rejeitar_item(
  IN p_codigo_rastreio CHAR(13)
)
BEGIN
  DECLARE v_qtd INT DEFAULT 0;

  SELECT COUNT(*) INTO v_qtd FROM item_residuo WHERE codigo_rastreio = p_codigo_rastreio;
  IF v_qtd = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Código de rastreio não encontrado.';
  END IF;

  -- a trigger trg_item_valida_status bloqueia se o item já foi reciclado
  UPDATE item_residuo SET status = 'REJEITADO' WHERE codigo_rastreio = p_codigo_rastreio;
END$$

DELIMITER ;
