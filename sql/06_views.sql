-- =====================================================================
-- EcoCircuito - Script 06: views
-- As views escondem os JOINs e são o que os perfis de leitura consultam.
-- =====================================================================
USE ecocircuito;

-- ---------------------------------------------------------------------
-- 1) Rastreio de um item (o que aparece ao ler o QR Code da etiqueta)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_rastreio_item AS
SELECT i.codigo_rastreio,
       i.descricao,
       c.nome                AS categoria,
       c.classe_risco,
       i.peso_kg,
       i.status,
       e.data_entrega,
       p.nome                AS ponto_coleta,
       l.id_lote,
       r.razao_social        AS reciclador,
       l.data_processamento,
       cd.codigo             AS certificado
  FROM item_residuo i
  JOIN categoria_residuo c       ON c.id_categoria = i.id_categoria
  JOIN entrega e                 ON e.id_entrega   = i.id_entrega
  JOIN ponto_coleta p            ON p.id_ponto     = e.id_ponto
  LEFT JOIN lote l               ON l.id_lote      = i.id_lote
  LEFT JOIN reciclador r         ON r.id_reciclador = l.id_reciclador
  LEFT JOIN certificado_destinacao cd ON cd.id_lote = l.id_lote;

-- ---------------------------------------------------------------------
-- 2) Kg coletados por mês e categoria (sem contar rejeitados)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_coleta_mensal AS
SELECT DATE_FORMAT(e.data_entrega, '%Y-%m') AS mes,
       c.nome                               AS categoria,
       COUNT(*)                             AS qtd_itens,
       SUM(i.peso_kg)                       AS total_kg
  FROM item_residuo i
  JOIN entrega e           ON e.id_entrega   = i.id_entrega
  JOIN categoria_residuo c ON c.id_categoria = i.id_categoria
 WHERE i.status <> 'REJEITADO'
 GROUP BY DATE_FORMAT(e.data_entrega, '%Y-%m'), c.nome;

-- ---------------------------------------------------------------------
-- 3) Impacto: materiais recuperados e valor estimado
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_impacto_materiais AS
SELECT m.nome                                   AS material,
       ROUND(SUM(rc.peso_kg), 3)                AS kg_recuperados,
       m.valor_kg_ref                           AS valor_kg_ref,
       ROUND(SUM(rc.peso_kg) * m.valor_kg_ref, 2) AS valor_estimado_reais
  FROM recuperacao rc
  JOIN material m ON m.id_material = rc.id_material
 GROUP BY m.id_material, m.nome, m.valor_kg_ref;

-- ---------------------------------------------------------------------
-- 4) Ranking de geradores (gamificação: 10 pontos por kg reciclado)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ranking_geradores AS
SELECT g.id_gerador,
       g.nome,
       g.tipo,
       mu.nome                                                    AS municipio,
       COUNT(DISTINCT e.id_entrega)                               AS entregas,
       SUM(CASE WHEN i.status <> 'REJEITADO' THEN i.peso_kg ELSE 0 END) AS kg_entregues,
       FLOOR(SUM(CASE WHEN i.status = 'RECICLADO' THEN i.peso_kg ELSE 0 END) * 10) AS pontos
  FROM gerador g
  JOIN municipio mu   ON mu.id_municipio = g.id_municipio
  JOIN entrega e      ON e.id_gerador    = g.id_gerador
  JOIN item_residuo i ON i.id_entrega    = e.id_entrega
 GROUP BY g.id_gerador, g.nome, g.tipo, mu.nome;

-- ---------------------------------------------------------------------
-- 5) Ocupação dos pontos de coleta (para saber quando mandar o caminhão)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ocupacao_pontos AS
SELECT p.id_ponto,
       p.nome,
       mu.nome AS municipio,
       p.capacidade_kg,
       COALESCE(SUM(i.peso_kg), 0) AS kg_aguardando,
       ROUND(COALESCE(SUM(i.peso_kg), 0) / p.capacidade_kg * 100, 1) AS ocupacao_pct
  FROM ponto_coleta p
  JOIN municipio mu ON mu.id_municipio = p.id_municipio
  LEFT JOIN entrega e      ON e.id_ponto = p.id_ponto
  LEFT JOIN item_residuo i ON i.id_entrega = e.id_entrega AND i.status = 'RECEBIDO'
 WHERE p.ativo = TRUE
 GROUP BY p.id_ponto, p.nome, mu.nome, p.capacidade_kg;

-- ---------------------------------------------------------------------
-- 6) Recicladores com licença vencida ou vencendo nos próximos 60 dias
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_licencas_alerta AS
SELECT id_reciclador,
       razao_social,
       numero_licenca,
       validade_licenca,
       DATEDIFF(validade_licenca, CURRENT_DATE()) AS dias_restantes,
       CASE WHEN validade_licenca < CURRENT_DATE() THEN 'VENCIDA'
            ELSE 'VENCENDO' END AS situacao
  FROM reciclador
 WHERE ativo = TRUE
   AND validade_licenca <= CURRENT_DATE() + INTERVAL 60 DAY;
