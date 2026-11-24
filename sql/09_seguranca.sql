-- =====================================================================
-- EcoCircuito - Script 09: segurança (perfis e usuários)
-- Princípio do menor privilégio: cada perfil só acessa o que precisa.
-- As senhas abaixo são exemplos e DEVEM ser trocadas em produção.
-- =====================================================================
USE ecocircuito;

DROP ROLE IF EXISTS 'eco_admin', 'eco_operador_ponto', 'eco_reciclador', 'eco_analista';
CREATE ROLE 'eco_admin', 'eco_operador_ponto', 'eco_reciclador', 'eco_analista';

-- Administrador do sistema: controle total do banco do projeto
GRANT ALL PRIVILEGES ON ecocircuito.* TO 'eco_admin';

-- Operador do ponto de coleta: consulta cadastros e registra entregas/lotes
-- (escreve apenas através das procedures, nunca direto nas tabelas)
GRANT SELECT ON ecocircuito.gerador           TO 'eco_operador_ponto';
GRANT SELECT ON ecocircuito.categoria_residuo TO 'eco_operador_ponto';
GRANT SELECT ON ecocircuito.ponto_coleta      TO 'eco_operador_ponto';
GRANT SELECT ON ecocircuito.vw_rastreio_item  TO 'eco_operador_ponto';
GRANT SELECT ON ecocircuito.vw_ocupacao_pontos TO 'eco_operador_ponto';
GRANT INSERT, UPDATE (nome, email, telefone, ativo) ON ecocircuito.gerador TO 'eco_operador_ponto';
GRANT EXECUTE ON PROCEDURE ecocircuito.sp_registrar_entrega TO 'eco_operador_ponto';
GRANT EXECUTE ON PROCEDURE ecocircuito.sp_enviar_lote       TO 'eco_operador_ponto';
GRANT EXECUTE ON PROCEDURE ecocircuito.sp_rejeitar_item     TO 'eco_operador_ponto';

-- Reciclador: só vê o rastreio e processa lotes
GRANT SELECT ON ecocircuito.vw_rastreio_item TO 'eco_reciclador';
GRANT EXECUTE ON PROCEDURE ecocircuito.sp_processar_lote TO 'eco_reciclador';
GRANT EXECUTE ON PROCEDURE ecocircuito.sp_rejeitar_item  TO 'eco_reciclador';

-- Analista / prefeitura: somente leitura nas views de indicadores
-- (não enxerga CPF, e-mail nem telefone dos geradores)
GRANT SELECT ON ecocircuito.vw_coleta_mensal     TO 'eco_analista';
GRANT SELECT ON ecocircuito.vw_impacto_materiais TO 'eco_analista';
GRANT SELECT ON ecocircuito.vw_ocupacao_pontos   TO 'eco_analista';
GRANT SELECT ON ecocircuito.vw_licencas_alerta   TO 'eco_analista';

-- Usuários de exemplo (um por perfil)
DROP USER IF EXISTS 'admin_eco'@'%', 'op_sbc'@'%', 'rec_recircuito'@'%', 'analista_pref'@'%';

CREATE USER 'admin_eco'@'%'      IDENTIFIED BY 'Troque#Admin2026'      PASSWORD EXPIRE INTERVAL 90 DAY FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
CREATE USER 'op_sbc'@'%'         IDENTIFIED BY 'Troque#Operador2026'   PASSWORD EXPIRE INTERVAL 90 DAY FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
CREATE USER 'rec_recircuito'@'%' IDENTIFIED BY 'Troque#Reciclador2026' PASSWORD EXPIRE INTERVAL 90 DAY FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
CREATE USER 'analista_pref'@'%'  IDENTIFIED BY 'Troque#Analista2026'   PASSWORD EXPIRE INTERVAL 90 DAY FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;

GRANT 'eco_admin'          TO 'admin_eco'@'%';
GRANT 'eco_operador_ponto' TO 'op_sbc'@'%';
GRANT 'eco_reciclador'     TO 'rec_recircuito'@'%';
GRANT 'eco_analista'       TO 'analista_pref'@'%';

SET DEFAULT ROLE ALL TO 'admin_eco'@'%', 'op_sbc'@'%', 'rec_recircuito'@'%', 'analista_pref'@'%';

-- Conferir o que cada perfil pode fazer:
SHOW GRANTS FOR 'eco_operador_ponto';
SHOW GRANTS FOR 'eco_analista';
