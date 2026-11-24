-- =====================================================================
-- EcoCircuito - Script 08: consultas para relatórios
-- =====================================================================
USE ecocircuito;

-- R1) Painel geral: indicadores de impacto
SELECT
  (SELECT COUNT(*) FROM gerador WHERE ativo)                            AS geradores_cadastrados,
  (SELECT COUNT(*) FROM item_residuo WHERE status <> 'REJEITADO')       AS itens_coletados,
  (SELECT SUM(peso_kg) FROM item_residuo WHERE status <> 'REJEITADO')   AS kg_coletados,
  (SELECT SUM(peso_kg) FROM item_residuo WHERE status = 'RECICLADO')    AS kg_reciclados,
  (SELECT ROUND(SUM(peso_kg), 1) FROM recuperacao r
     JOIN material m ON m.id_material = r.id_material
    WHERE m.nome <> 'Rejeito não reciclável')                           AS kg_materiais_recuperados,
  (SELECT SUM(valor_estimado_reais) FROM vw_impacto_materiais)          AS valor_recuperado_reais,
  (SELECT COUNT(*) FROM certificado_destinacao)                         AS certificados_emitidos;

-- R2) Taxa de reaproveitamento: % do peso reciclado que virou material útil
SELECT ROUND(100 * SUM(CASE WHEN m.nome <> 'Rejeito não reciclável' THEN r.peso_kg ELSE 0 END)
             / SUM(r.peso_kg), 1) AS taxa_reaproveitamento_pct
  FROM recuperacao r
  JOIN material m ON m.id_material = r.id_material;

-- R3) Kg coletados por mês (evolução)
SELECT mes, SUM(qtd_itens) AS itens, SUM(total_kg) AS kg
  FROM vw_coleta_mensal
 GROUP BY mes
 ORDER BY mes;

-- R4) Kg por categoria e classe de risco
SELECT c.nome AS categoria, c.classe_risco, SUM(i.peso_kg) AS kg
  FROM item_residuo i
  JOIN categoria_residuo c ON c.id_categoria = i.id_categoria
 WHERE i.status <> 'REJEITADO'
 GROUP BY c.nome, c.classe_risco
 ORDER BY kg DESC;

-- R5) Materiais recuperados e valor estimado
SELECT * FROM vw_impacto_materiais ORDER BY valor_estimado_reais DESC;

-- R6) Top 5 geradores (ranking da gamificação)
SELECT nome, tipo, municipio, entregas, kg_entregues, pontos
  FROM vw_ranking_geradores
 ORDER BY pontos DESC, kg_entregues DESC
 LIMIT 5;

-- R7) Ocupação dos pontos: quem precisa de caminhão primeiro
SELECT * FROM vw_ocupacao_pontos ORDER BY ocupacao_pct DESC;

-- R8) Desempenho dos recicladores: kg recebidos e tempo médio de processamento
SELECT r.razao_social,
       COUNT(DISTINCT l.id_lote)                                     AS lotes,
       SUM(i.peso_kg)                                                AS kg_recebidos,
       ROUND(AVG(DATEDIFF(l.data_processamento, l.data_envio)), 1)  AS dias_medios_processamento
  FROM reciclador r
  JOIN lote l         ON l.id_reciclador = r.id_reciclador
  JOIN item_residuo i ON i.id_lote       = l.id_lote
 GROUP BY r.razao_social
 ORDER BY kg_recebidos DESC;

-- R9) Lotes enviados há mais de 30 dias e ainda não processados (alerta)
SELECT l.id_lote, r.razao_social, l.data_envio,
       DATEDIFF(CURRENT_DATE(), l.data_envio) AS dias_em_aberto
  FROM lote l
  JOIN reciclador r ON r.id_reciclador = l.id_reciclador
 WHERE l.status = 'ENVIADO'
   AND l.data_envio < CURRENT_DATE() - INTERVAL 30 DAY;

-- R10) Recicladores com licença vencida ou vencendo
SELECT * FROM vw_licencas_alerta ORDER BY validade_licenca;

-- R11) Rastreio completo de um item (exemplo com o primeiro item cadastrado)
SELECT * FROM vw_rastreio_item
 WHERE codigo_rastreio = (SELECT codigo_rastreio FROM item_residuo ORDER BY id_item LIMIT 1);

-- R12) Linha do tempo do mesmo item (trilha de auditoria)
SELECT h.status_anterior, h.status_novo, h.data_hora, h.usuario_bd
  FROM historico_status h
 WHERE h.id_item = (SELECT MIN(id_item) FROM item_residuo)
 ORDER BY h.id_historico;
