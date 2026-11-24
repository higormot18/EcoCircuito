-- =====================================================================
-- EcoCircuito - Script 04: triggers
-- =====================================================================
USE ecocircuito;

DELIMITER $$

-- ---------------------------------------------------------------------
-- 1) Gera o código de rastreio do item automaticamente (ex.: EC-4F9A1C2B7D)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_item_gera_codigo
BEFORE INSERT ON item_residuo
FOR EACH ROW
BEGIN
  IF NEW.codigo_rastreio IS NULL OR NEW.codigo_rastreio = '' THEN
    SET NEW.codigo_rastreio = CONCAT('EC-', UPPER(LEFT(MD5(UUID()), 10)));
  END IF;
END$$

-- ---------------------------------------------------------------------
-- 2) Registra no histórico o primeiro status do item
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_item_historico_insert
AFTER INSERT ON item_residuo
FOR EACH ROW
BEGIN
  INSERT INTO historico_status (id_item, status_anterior, status_novo, usuario_bd)
  VALUES (NEW.id_item, NULL, NEW.status, CURRENT_USER());
END$$

-- ---------------------------------------------------------------------
-- 3) Impede status "voltar para trás" e registra toda mudança no histórico
--    Fluxo válido: RECEBIDO -> ENVIADO -> RECICLADO
--                  RECEBIDO/ENVIADO -> REJEITADO
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_item_valida_status
BEFORE UPDATE ON item_residuo
FOR EACH ROW
BEGIN
  IF NEW.status <> OLD.status AND NOT (
        (OLD.status = 'RECEBIDO' AND NEW.status IN ('ENVIADO','REJEITADO'))
     OR (OLD.status = 'ENVIADO'  AND NEW.status IN ('RECICLADO','REJEITADO'))
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Mudança de status inválida para o item.';
  END IF;
END$$

CREATE TRIGGER trg_item_historico_update
AFTER UPDATE ON item_residuo
FOR EACH ROW
BEGIN
  IF NEW.status <> OLD.status THEN
    INSERT INTO historico_status (id_item, status_anterior, status_novo, usuario_bd)
    VALUES (NEW.id_item, OLD.status, NEW.status, CURRENT_USER());
  END IF;
END$$

-- ---------------------------------------------------------------------
-- 4) Só deixa criar lote para reciclador ativo e com licença em dia
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_lote_valida_reciclador
BEFORE INSERT ON lote
FOR EACH ROW
BEGIN
  DECLARE v_ativo    BOOLEAN;
  DECLARE v_validade DATE;

  SELECT ativo, validade_licenca
    INTO v_ativo, v_validade
    FROM reciclador
   WHERE id_reciclador = NEW.id_reciclador;

  IF v_ativo IS NULL OR v_ativo = FALSE THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Reciclador inexistente ou inativo.';
  END IF;

  IF v_validade < CURRENT_DATE() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Licença ambiental do reciclador está vencida.';
  END IF;
END$$

DELIMITER ;
