-- =====================================================================
-- EcoCircuito - Script 11: monitoramento e administração
-- Consultas que o administrador roda no dia a dia.
-- =====================================================================
USE ecocircuito;

-- M1) Tamanho de cada tabela (crescimento do banco)
SELECT table_name                                         AS tabela,
       table_rows                                         AS linhas_aprox,
       ROUND((data_length + index_length) / 1024, 1)      AS tamanho_kb
  FROM information_schema.tables
 WHERE table_schema = 'ecocircuito' AND table_type = 'BASE TABLE'
 ORDER BY (data_length + index_length) DESC;

-- M2) Consultas mais pesadas (performance_schema)
SELECT LEFT(digest_text, 80)                    AS consulta,
       count_star                               AS execucoes,
       ROUND(avg_timer_wait / 1000000000, 2)    AS media_ms
  FROM performance_schema.events_statements_summary_by_digest
 WHERE schema_name = 'ecocircuito'
 ORDER BY avg_timer_wait DESC
 LIMIT 10;

-- M3) Índices que nunca foram usados (candidatos a remoção)
SELECT object_name AS tabela, index_name AS indice
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE object_schema = 'ecocircuito'
   AND index_name IS NOT NULL AND index_name <> 'PRIMARY'
   AND count_star = 0;

-- M4) Conexões abertas por usuário (detectar acesso estranho)
SELECT user, host, COUNT(*) AS conexoes
  FROM information_schema.processlist
 GROUP BY user, host;

-- M5) Mudanças de status nas últimas 24h, por usuário do banco (auditoria)
SELECT usuario_bd, status_novo, COUNT(*) AS qtd
  FROM historico_status
 WHERE data_hora >= NOW() - INTERVAL 1 DAY
 GROUP BY usuario_bd, status_novo;

-- M6) Ligar o log de consultas lentas (acima de 2 segundos) - requer admin
-- SET GLOBAL slow_query_log = 'ON';
-- SET GLOBAL long_query_time = 2;
