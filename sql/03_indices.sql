-- =====================================================================
-- EcoCircuito - Script 03: índices
-- As PKs, UNIQUEs e FKs já criam índices automaticamente no InnoDB.
-- Aqui ficam os índices extras para as consultas mais usadas.
-- =====================================================================
USE ecocircuito;

-- Itens parados no ponto (status) e itens de um ponto por categoria
CREATE INDEX idx_item_status        ON item_residuo (status);
CREATE INDEX idx_item_categoria_st  ON item_residuo (id_categoria, status);

-- Relatórios por período (kg por mês, ranking)
CREATE INDEX idx_entrega_data       ON entrega (data_entrega);
CREATE INDEX idx_entrega_ponto_data ON entrega (id_ponto, data_entrega);

-- Lotes por situação e por reciclador
CREATE INDEX idx_lote_status        ON lote (status, data_envio);

-- Alerta de licenças vencendo
CREATE INDEX idx_reciclador_validade ON reciclador (validade_licenca);

-- Linha do tempo de um item (rastreio)
CREATE INDEX idx_historico_item_data ON historico_status (id_item, data_hora);
