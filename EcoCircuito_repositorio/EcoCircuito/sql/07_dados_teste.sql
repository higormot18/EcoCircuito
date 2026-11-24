-- =====================================================================
-- EcoCircuito - Script 07: dados de teste
-- Dados fictícios. Os valores de R$/kg e os percentuais de composição
-- são de referência para demonstração e podem ser ajustados.
-- As entregas e lotes passam pelas procedures, então triggers e
-- validações são exercitadas durante a carga.
-- =====================================================================
USE ecocircuito;

-- ---------------- Cadastros básicos ----------------
INSERT INTO municipio (nome, uf) VALUES
 ('São Bernardo do Campo','SP'), ('Santo André','SP'), ('São Caetano do Sul','SP'),
 ('Diadema','SP'), ('Mauá','SP'), ('São Paulo','SP'), ('Guarulhos','SP');

INSERT INTO categoria_residuo (nome, classe_risco, descricao) VALUES
 ('Informática',        'MEDIO', 'Computadores, notebooks, impressoras, periféricos'),
 ('Celulares e tablets','MEDIO', 'Smartphones, tablets e acessórios'),
 ('Pilhas e baterias',  'ALTO',  'Pilhas, baterias de lítio e baterias de notebook'),
 ('Monitores e TVs',    'ALTO',  'Monitores e televisores (LCD, LED e tubo)'),
 ('Eletroportáteis',    'BAIXO', 'Liquidificador, secador, ferro de passar, etc.'),
 ('Cabos e fios',       'BAIXO', 'Cabos de energia, rede, carregadores');

INSERT INTO material (nome, valor_kg_ref) VALUES
 ('Plástico', 2.50), ('Ferro e aço', 1.20), ('Alumínio', 8.00), ('Cobre', 38.00),
 ('Vidro', 0.30), ('Placas de circuito', 25.00), ('Baterias (lítio e outros)', 15.00),
 ('Rejeito não reciclável', 0.00);

-- composição média (%) de cada categoria - cada categoria soma 100%
INSERT INTO composicao_categoria (id_categoria, id_material, percentual) VALUES
 (1,1,25),(1,2,40),(1,3,8),(1,4,7),(1,6,12),(1,8,8),
 (2,1,35),(2,5,15),(2,4,10),(2,6,22),(2,7,15),(2,8,3),
 (3,7,60),(3,2,20),(3,1,5),(3,8,15),
 (4,5,45),(4,1,25),(4,2,15),(4,4,5),(4,6,5),(4,8,5),
 (5,1,45),(5,2,30),(5,4,10),(5,3,5),(5,6,3),(5,8,7),
 (6,4,55),(6,1,40),(6,8,5);

INSERT INTO ponto_coleta (nome, endereco, id_municipio, capacidade_kg) VALUES
 ('EcoPonto Centro SBC',       'Rua Marechal Deodoro, 1000',      1, 500),
 ('EcoPonto Santo André',      'Av. Industrial, 600',             2, 800),
 ('EcoPonto São Caetano',      'Rua Manoel Coelho, 300',          3, 300),
 ('EcoPonto Diadema',          'Av. Alda, 250',                   4, 400),
 ('EcoPonto Paulista',         'Av. Paulista, 1500',              6, 1000);

INSERT INTO reciclador (razao_social, cnpj, numero_licenca, validade_licenca, id_municipio, ativo) VALUES
 ('ReCircuito Reciclagem Ltda',      '11222333000181', 'LO-SP-2025-0412', '2028-03-31', 1, TRUE),
 ('Verde Metais Recuperação Ltda',   '22333444000192', 'LO-SP-2024-1187', '2027-09-30', 7, TRUE),
 ('ABC Logística Reversa S.A.',      '33444555000103', 'LO-SP-2023-0905', '2027-01-10', 2, TRUE),
 ('Antiga Sucatas ME',               '44555666000114', 'LO-SP-2021-0333', '2026-08-31', 5, TRUE);

INSERT INTO gerador (tipo, nome, documento, email, telefone, id_municipio, data_cadastro) VALUES
 ('PF','Ana Paula Ribeiro',        '11111111101','ana.ribeiro@example.com',   '11990000001',1,'2026-05-20 10:00:00'),
 ('PF','Bruno Carvalho',           '11111111102','bruno.carvalho@example.com','11990000002',1,'2026-05-22 14:30:00'),
 ('PF','Camila Souza',             '11111111103','camila.souza@example.com',  '11990000003',2,'2026-06-01 09:15:00'),
 ('PF','Diego Fernandes',          '11111111104','diego.f@example.com',       '11990000004',3,'2026-06-03 18:40:00'),
 ('PF','Elaine Martins',           '11111111105','elaine.m@example.com',      '11990000005',4,'2026-06-10 11:00:00'),
 ('PF','Fábio Lima',               '11111111106','fabio.lima@example.com',    '11990000006',6,'2026-06-12 16:20:00'),
 ('PF','Gabriela Nunes',           '11111111107','gabi.nunes@example.com',    '11990000007',6,'2026-07-01 08:45:00'),
 ('PF','Henrique Alves',           '11111111108','h.alves@example.com',       NULL,         2,'2026-07-15 13:10:00'),
 ('PJ','Escola Estadual Vila Rica','10101010000101','contato@eevilarica.example.com','1143000001',1,'2026-05-25 09:00:00'),
 ('PJ','Mercado Bom Preço Ltda',   '20202020000102','adm@bompreco.example.com',     '1144000002',2,'2026-06-05 10:30:00'),
 ('PJ','TechFix Assistência Técnica','30303030000103','oficina@techfix.example.com','1145000003',4,'2026-06-18 15:00:00'),
 ('PJ','Condomínio Parque das Flores','40404040000104','sindico@parqueflores.example.com',NULL,6,'2026-07-08 19:00:00');

-- ---------------- Entregas (via procedure) ----------------
-- Junho/Julho 2026
CALL sp_registrar_entrega(1, 1, '[{"categoria":1,"descricao":"Notebook antigo","peso":2.4},{"categoria":6,"descricao":"Cabos diversos","peso":1.1}]', '2026-06-05 10:12:00', @e);
CALL sp_registrar_entrega(9, 1, '[{"categoria":1,"descricao":"Desktops do laboratório (6 un.)","peso":48.0},{"categoria":4,"descricao":"Monitores LCD (6 un.)","peso":21.0},{"categoria":6,"descricao":"Cabos de rede e energia","peso":7.5}]', '2026-06-08 08:30:00', @e);
CALL sp_registrar_entrega(2, 1, '[{"categoria":2,"descricao":"Celulares antigos (3 un.)","peso":0.6},{"categoria":3,"descricao":"Pilhas AA e AAA","peso":0.9}]', '2026-06-14 17:45:00', @e);
CALL sp_registrar_entrega(3, 2, '[{"categoria":5,"descricao":"Liquidificador","peso":2.8},{"categoria":5,"descricao":"Secador de cabelo","peso":0.7}]', '2026-06-16 12:05:00', @e);
CALL sp_registrar_entrega(10,2, '[{"categoria":1,"descricao":"Impressoras fiscais (4 un.)","peso":16.0},{"categoria":6,"descricao":"Cabos e fontes","peso":5.2},{"categoria":4,"descricao":"Monitor de caixa","peso":4.1}]', '2026-06-20 09:40:00', @e);
CALL sp_registrar_entrega(4, 3, '[{"categoria":4,"descricao":"TV de tubo 21 pol.","peso":24.0}]', '2026-06-22 15:00:00', @e);
CALL sp_registrar_entrega(11,4, '[{"categoria":2,"descricao":"Celulares sem conserto (25 un.)","peso":4.8},{"categoria":3,"descricao":"Baterias de celular (40 un.)","peso":1.9},{"categoria":1,"descricao":"Placas e peças de notebook","peso":6.3}]', '2026-06-29 18:10:00', @e);
CALL sp_registrar_entrega(5, 4, '[{"categoria":5,"descricao":"Ferro de passar","peso":1.2}]', '2026-07-03 10:00:00', @e);
CALL sp_registrar_entrega(6, 5, '[{"categoria":1,"descricao":"Notebook","peso":2.1},{"categoria":2,"descricao":"Tablet","peso":0.5}]', '2026-07-06 19:20:00', @e);
CALL sp_registrar_entrega(12,5, '[{"categoria":3,"descricao":"Pilhas coletadas no condomínio","peso":12.4},{"categoria":5,"descricao":"Eletroportáteis diversos","peso":18.6},{"categoria":6,"descricao":"Cabos e carregadores","peso":6.0}]', '2026-07-12 11:00:00', @e);
CALL sp_registrar_entrega(7, 5, '[{"categoria":4,"descricao":"Monitor LED 24 pol.","peso":3.4}]', '2026-07-19 14:25:00', @e);
CALL sp_registrar_entrega(1, 1, '[{"categoria":5,"descricao":"Micro-ondas pequeno","peso":10.5}]', '2026-07-24 09:10:00', @e);

-- Lotes de julho: enviados e processados
CALL sp_enviar_lote(1, 1, '2026-07-28 08:00:00', @l1);
CALL sp_enviar_lote(2, 3, '2026-07-28 10:00:00', @l2);
CALL sp_enviar_lote(4, 2, '2026-07-29 09:00:00', @l3);
CALL sp_enviar_lote(5, 2, '2026-07-30 09:00:00', @l4);
CALL sp_processar_lote(@l1, '2026-08-05 16:00:00');
CALL sp_processar_lote(@l2, '2026-08-06 16:00:00');
CALL sp_processar_lote(@l3, '2026-08-07 16:00:00');
CALL sp_processar_lote(@l4, '2026-08-08 16:00:00');

-- Agosto/Setembro 2026
CALL sp_registrar_entrega(8, 2, '[{"categoria":2,"descricao":"Smartphone quebrado","peso":0.2},{"categoria":6,"descricao":"Carregadores","peso":0.4}]', '2026-08-04 13:00:00', @e);
CALL sp_registrar_entrega(9, 1, '[{"categoria":1,"descricao":"Projetores e periféricos","peso":9.8},{"categoria":3,"descricao":"Baterias de nobreak","peso":14.0}]', '2026-08-11 08:20:00', @e);
CALL sp_registrar_entrega(2, 1, '[{"categoria":1,"descricao":"Roteador e modem","peso":0.9}]', '2026-08-15 18:00:00', @e);
CALL sp_registrar_entrega(11,4, '[{"categoria":2,"descricao":"Celulares sem conserto (30 un.)","peso":5.6},{"categoria":3,"descricao":"Baterias de celular (35 un.)","peso":1.6}]', '2026-08-27 18:05:00', @e);
CALL sp_registrar_entrega(10,2, '[{"categoria":4,"descricao":"TVs de exposição (2 un.)","peso":17.5},{"categoria":5,"descricao":"Eletroportáteis com defeito","peso":11.0}]', '2026-09-02 10:10:00', @e);
CALL sp_registrar_entrega(4, 3, '[{"categoria":1,"descricao":"Desktop antigo","peso":8.7},{"categoria":6,"descricao":"Cabos","peso":1.3}]', '2026-09-09 16:30:00', @e);
CALL sp_registrar_entrega(7, 5, '[{"categoria":2,"descricao":"Celular","peso":0.2},{"categoria":3,"descricao":"Pilhas","peso":0.6}]', '2026-09-14 12:40:00', @e);
CALL sp_registrar_entrega(12,5, '[{"categoria":3,"descricao":"Pilhas coletadas no condomínio","peso":9.8},{"categoria":6,"descricao":"Cabos e extensões","peso":4.7},{"categoria":1,"descricao":"Impressora jato de tinta","peso":5.5}]', '2026-09-20 10:00:00', @e);

-- Lotes de setembro
CALL sp_enviar_lote(1, 1, '2026-09-25 08:00:00', @l5);
CALL sp_enviar_lote(4, 2, '2026-09-25 11:00:00', @l6);
CALL sp_enviar_lote(2, 1, '2026-09-28 09:00:00', @l7);
CALL sp_processar_lote(@l5, '2026-10-02 15:00:00');
CALL sp_processar_lote(@l6, '2026-10-03 15:00:00');
-- @l7 continua ENVIADO (ainda no reciclador)

-- Outubro/Novembro 2026 (ainda nos pontos)
CALL sp_registrar_entrega(3, 2, '[{"categoria":2,"descricao":"Tablet com tela quebrada","peso":0.6}]', '2026-10-06 11:30:00', @e);
CALL sp_registrar_entrega(5, 4, '[{"categoria":1,"descricao":"Notebook","peso":2.2},{"categoria":5,"descricao":"Batedeira","peso":2.9}]', '2026-10-13 17:15:00', @e);
CALL sp_registrar_entrega(9, 1, '[{"categoria":4,"descricao":"Monitores CRT (3 un.)","peso":36.0},{"categoria":1,"descricao":"Teclados e mouses","peso":4.4}]', '2026-10-21 08:10:00', @e);
CALL sp_registrar_entrega(6, 5, '[{"categoria":5,"descricao":"Aspirador de pó","peso":4.3}]', '2026-10-28 18:30:00', @e);
CALL sp_registrar_entrega(11,4, '[{"categoria":2,"descricao":"Celulares sem conserto (20 un.)","peso":3.9},{"categoria":3,"descricao":"Baterias de celular (25 un.)","peso":1.2}]', '2026-11-05 18:00:00', @e);
CALL sp_registrar_entrega(1, 1, '[{"categoria":6,"descricao":"Fios de instalação antiga","peso":6.8}]', '2026-11-10 09:45:00', @e);
CALL sp_registrar_entrega(12,5, '[{"categoria":3,"descricao":"Pilhas coletadas no condomínio","peso":8.1}]', '2026-11-17 10:00:00', @e);
CALL sp_registrar_entrega(3, 2, '[{"categoria":5,"descricao":"Lâmpada comum (não é eletrônico)","peso":0.3}]', '2026-11-19 12:00:00', @e);

-- item que não é resíduo eletrônico é rejeitado na triagem
SET @cod_rej = (SELECT codigo_rastreio FROM item_residuo WHERE descricao LIKE 'Lâmpada comum%' LIMIT 1);
CALL sp_rejeitar_item(@cod_rej);
