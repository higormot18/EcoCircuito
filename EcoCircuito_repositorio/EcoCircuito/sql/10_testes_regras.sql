-- =====================================================================
-- EcoCircuito - Script 10: testes das regras de integridade
-- Cada comando abaixo DEVE FALHAR. Rode com:  mysql --force < 10_testes_regras.sql
-- Serve para demonstrar constraints, triggers e transações na apresentação.
-- =====================================================================
USE ecocircuito;

-- T1) CHECK: peso negativo                      -> erro ck_item_peso
INSERT INTO item_residuo (id_entrega, id_categoria, descricao, peso_kg)
VALUES (1, 1, 'Teste peso negativo', -5);

-- T2) CHECK: CPF com tamanho errado             -> erro ck_gerador_documento
INSERT INTO gerador (tipo, nome, documento, email, id_municipio)
VALUES ('PF', 'Teste CPF', '123', 'teste.cpf@example.com', 1);

-- T3) UNIQUE: documento repetido                -> erro uq_gerador_documento
INSERT INTO gerador (tipo, nome, documento, email, id_municipio)
VALUES ('PF', 'Cópia da Ana', '11111111101', 'copia@example.com', 1);

-- T4) FK: entrega para gerador que não existe   -> erro fk_entrega_gerador
INSERT INTO entrega (id_gerador, id_ponto) VALUES (9999, 1);

-- T5) FK com RESTRICT: apagar município em uso  -> erro fk_gerador_municipio
DELETE FROM municipio WHERE id_municipio = 1;

-- T6) TRIGGER: lote para reciclador com licença vencida -> "Licença ambiental ... vencida"
CALL sp_enviar_lote(1, 4, NULL, @x);

-- T7) TRIGGER: item reciclado não pode voltar a RECEBIDO -> "Mudança de status inválida"
UPDATE item_residuo SET status = 'RECEBIDO' WHERE status = 'RECICLADO' LIMIT 1;

-- T8) PROCEDURE: processar o mesmo lote duas vezes -> "Lote já foi processado."
CALL sp_processar_lote(1, NULL);

-- T9) TRANSAÇÃO: entrega com um item válido e um inválido (peso 0).
--     Nada é gravado: nem a entrega, nem o item válido (ROLLBACK).
SELECT COUNT(*) INTO @entregas_antes FROM entrega;
CALL sp_registrar_entrega(1, 1,
  '[{"categoria":1,"descricao":"Item válido","peso":1.0},{"categoria":1,"descricao":"Item inválido","peso":0}]',
  NULL, @e);
SELECT @entregas_antes AS entregas_antes,
       (SELECT COUNT(*) FROM entrega) AS entregas_depois,
       IF(@entregas_antes = (SELECT COUNT(*) FROM entrega), 'ROLLBACK OK', 'FALHOU') AS resultado_t9;

-- T10) PROCEDURE: capacidade do ponto excedida -> "Capacidade do ponto de coleta excedida"
CALL sp_registrar_entrega(3, 3, '[{"categoria":4,"descricao":"Carga gigante","peso":900}]', NULL, @e);
