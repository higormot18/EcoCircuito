-- =====================================================================
-- EcoCircuito - Script 02: tabelas e constraints
-- Todas as tabelas em InnoDB (suporta transações e chaves estrangeiras).
-- Modelo normalizado até a 3ª Forma Normal.
-- =====================================================================
USE ecocircuito;

-- ---------------------------------------------------------------------
-- MUNICÍPIO: evita repetir cidade/UF em cada cadastro (3FN)
-- ---------------------------------------------------------------------
CREATE TABLE municipio (
  id_municipio   INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(80)      NOT NULL,
  uf             CHAR(2)          NOT NULL,
  CONSTRAINT pk_municipio PRIMARY KEY (id_municipio),
  CONSTRAINT uq_municipio_nome_uf UNIQUE (nome, uf),
  CONSTRAINT ck_municipio_uf CHECK (uf REGEXP '^[A-Z]{2}$')
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- GERADOR: quem descarta o eletrônico (pessoa física ou empresa)
-- ---------------------------------------------------------------------
CREATE TABLE gerador (
  id_gerador     INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  tipo           ENUM('PF','PJ')  NOT NULL,
  nome           VARCHAR(120)     NOT NULL,
  documento      VARCHAR(14)      NOT NULL COMMENT 'CPF (11) ou CNPJ (14), só números',
  email          VARCHAR(120)     NOT NULL,
  telefone       VARCHAR(15)      NULL,
  id_municipio   INT UNSIGNED     NOT NULL,
  data_cadastro  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ativo          BOOLEAN          NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_gerador PRIMARY KEY (id_gerador),
  CONSTRAINT uq_gerador_documento UNIQUE (documento),
  CONSTRAINT uq_gerador_email UNIQUE (email),
  CONSTRAINT ck_gerador_documento CHECK (
        (tipo = 'PF' AND documento REGEXP '^[0-9]{11}$')
     OR (tipo = 'PJ' AND documento REGEXP '^[0-9]{14}$')),
  CONSTRAINT ck_gerador_email CHECK (email LIKE '%_@_%._%'),
  CONSTRAINT fk_gerador_municipio FOREIGN KEY (id_municipio)
    REFERENCES municipio (id_municipio) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- RECICLADOR: empresa licenciada que recebe e processa os lotes
-- ---------------------------------------------------------------------
CREATE TABLE reciclador (
  id_reciclador     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  razao_social      VARCHAR(150)  NOT NULL,
  cnpj              CHAR(14)      NOT NULL,
  numero_licenca    VARCHAR(30)   NOT NULL COMMENT 'Licença ambiental de operação',
  validade_licenca  DATE          NOT NULL,
  id_municipio      INT UNSIGNED  NOT NULL,
  ativo             BOOLEAN       NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_reciclador PRIMARY KEY (id_reciclador),
  CONSTRAINT uq_reciclador_cnpj UNIQUE (cnpj),
  CONSTRAINT uq_reciclador_licenca UNIQUE (numero_licenca),
  CONSTRAINT ck_reciclador_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$'),
  CONSTRAINT fk_reciclador_municipio FOREIGN KEY (id_municipio)
    REFERENCES municipio (id_municipio) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- PONTO DE COLETA: local onde o gerador entrega o eletrônico
-- ---------------------------------------------------------------------
CREATE TABLE ponto_coleta (
  id_ponto       INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(100)   NOT NULL,
  endereco       VARCHAR(150)   NOT NULL,
  id_municipio   INT UNSIGNED   NOT NULL,
  capacidade_kg  DECIMAL(10,2)  NOT NULL,
  ativo          BOOLEAN        NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_ponto_coleta PRIMARY KEY (id_ponto),
  CONSTRAINT uq_ponto_nome UNIQUE (nome),
  CONSTRAINT ck_ponto_capacidade CHECK (capacidade_kg > 0),
  CONSTRAINT fk_ponto_municipio FOREIGN KEY (id_municipio)
    REFERENCES municipio (id_municipio) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- CATEGORIA DE RESÍDUO: tipo de eletrônico e nível de risco
-- ---------------------------------------------------------------------
CREATE TABLE categoria_residuo (
  id_categoria   INT UNSIGNED                  NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(60)                   NOT NULL,
  classe_risco   ENUM('BAIXO','MEDIO','ALTO')  NOT NULL,
  descricao      VARCHAR(255)                  NULL,
  CONSTRAINT pk_categoria_residuo PRIMARY KEY (id_categoria),
  CONSTRAINT uq_categoria_nome UNIQUE (nome)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- MATERIAL: o que pode ser recuperado (cobre, plástico, ouro...)
-- ---------------------------------------------------------------------
CREATE TABLE material (
  id_material    INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(60)    NOT NULL,
  valor_kg_ref   DECIMAL(12,2)  NOT NULL COMMENT 'Valor de referência em R$/kg (configurável)',
  CONSTRAINT pk_material PRIMARY KEY (id_material),
  CONSTRAINT uq_material_nome UNIQUE (nome),
  CONSTRAINT ck_material_valor CHECK (valor_kg_ref >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- COMPOSIÇÃO: quanto (%) de cada material existe em cada categoria
-- Resolve o relacionamento N:N entre categoria e material
-- ---------------------------------------------------------------------
CREATE TABLE composicao_categoria (
  id_categoria   INT UNSIGNED   NOT NULL,
  id_material    INT UNSIGNED   NOT NULL,
  percentual     DECIMAL(5,2)   NOT NULL,
  CONSTRAINT pk_composicao PRIMARY KEY (id_categoria, id_material),
  CONSTRAINT ck_composicao_percentual CHECK (percentual > 0 AND percentual <= 100),
  CONSTRAINT fk_composicao_categoria FOREIGN KEY (id_categoria)
    REFERENCES categoria_residuo (id_categoria) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_composicao_material FOREIGN KEY (id_material)
    REFERENCES material (id_material) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- ENTREGA: cabeçalho de uma entrega do gerador em um ponto de coleta
-- ---------------------------------------------------------------------
CREATE TABLE entrega (
  id_entrega     INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  id_gerador     INT UNSIGNED   NOT NULL,
  id_ponto       INT UNSIGNED   NOT NULL,
  data_entrega   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observacao     VARCHAR(255)   NULL,
  CONSTRAINT pk_entrega PRIMARY KEY (id_entrega),
  CONSTRAINT fk_entrega_gerador FOREIGN KEY (id_gerador)
    REFERENCES gerador (id_gerador) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_entrega_ponto FOREIGN KEY (id_ponto)
    REFERENCES ponto_coleta (id_ponto) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- LOTE: conjunto de itens enviados de um ponto para um reciclador
-- ---------------------------------------------------------------------
CREATE TABLE lote (
  id_lote             INT UNSIGNED                 NOT NULL AUTO_INCREMENT,
  id_ponto            INT UNSIGNED                 NOT NULL,
  id_reciclador       INT UNSIGNED                 NOT NULL,
  data_envio          DATETIME                     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data_processamento  DATETIME                     NULL,
  status              ENUM('ENVIADO','PROCESSADO') NOT NULL DEFAULT 'ENVIADO',
  CONSTRAINT pk_lote PRIMARY KEY (id_lote),
  CONSTRAINT ck_lote_datas CHECK (data_processamento IS NULL OR data_processamento >= data_envio),
  CONSTRAINT ck_lote_status CHECK (
        (status = 'ENVIADO'    AND data_processamento IS NULL)
     OR (status = 'PROCESSADO' AND data_processamento IS NOT NULL)),
  CONSTRAINT fk_lote_ponto FOREIGN KEY (id_ponto)
    REFERENCES ponto_coleta (id_ponto) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_lote_reciclador FOREIGN KEY (id_reciclador)
    REFERENCES reciclador (id_reciclador) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- ITEM DE RESÍDUO: cada eletrônico entregue, com código de rastreio
-- ---------------------------------------------------------------------
CREATE TABLE item_residuo (
  id_item          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  codigo_rastreio  CHAR(13)       NOT NULL COMMENT 'Código impresso na etiqueta/QR Code',
  id_entrega       INT UNSIGNED   NOT NULL,
  id_categoria     INT UNSIGNED   NOT NULL,
  id_lote          INT UNSIGNED   NULL     COMMENT 'Preenchido quando o item sai do ponto',
  descricao        VARCHAR(120)   NOT NULL,
  peso_kg          DECIMAL(8,2)   NOT NULL,
  status           ENUM('RECEBIDO','ENVIADO','RECICLADO','REJEITADO') NOT NULL DEFAULT 'RECEBIDO',
  CONSTRAINT pk_item_residuo PRIMARY KEY (id_item),
  CONSTRAINT uq_item_codigo UNIQUE (codigo_rastreio),
  CONSTRAINT ck_item_peso CHECK (peso_kg > 0 AND peso_kg <= 1000),
  CONSTRAINT fk_item_entrega FOREIGN KEY (id_entrega)
    REFERENCES entrega (id_entrega) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_item_categoria FOREIGN KEY (id_categoria)
    REFERENCES categoria_residuo (id_categoria) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_item_lote FOREIGN KEY (id_lote)
    REFERENCES lote (id_lote) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- RECUPERAÇÃO: quantos kg de cada material saíram de cada lote
-- ---------------------------------------------------------------------
CREATE TABLE recuperacao (
  id_lote       INT UNSIGNED   NOT NULL,
  id_material   INT UNSIGNED   NOT NULL,
  peso_kg       DECIMAL(10,3)  NOT NULL,
  CONSTRAINT pk_recuperacao PRIMARY KEY (id_lote, id_material),
  CONSTRAINT ck_recuperacao_peso CHECK (peso_kg >= 0),
  CONSTRAINT fk_recuperacao_lote FOREIGN KEY (id_lote)
    REFERENCES lote (id_lote) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_recuperacao_material FOREIGN KEY (id_material)
    REFERENCES material (id_material) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- CERTIFICADO DE DESTINAÇÃO: comprovante emitido quando o lote é processado
-- (relação 1:1 com lote, garantida pela UNIQUE em id_lote)
-- ---------------------------------------------------------------------
CREATE TABLE certificado_destinacao (
  id_certificado  INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  id_lote         INT UNSIGNED   NOT NULL,
  codigo          VARCHAR(20)    NOT NULL COMMENT 'Formato CDF-AAAA-000000',
  data_emissao    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_certificado PRIMARY KEY (id_certificado),
  CONSTRAINT uq_certificado_lote UNIQUE (id_lote),
  CONSTRAINT uq_certificado_codigo UNIQUE (codigo),
  CONSTRAINT fk_certificado_lote FOREIGN KEY (id_lote)
    REFERENCES lote (id_lote) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- HISTÓRICO DE STATUS: trilha de auditoria preenchida por trigger
-- ---------------------------------------------------------------------
CREATE TABLE historico_status (
  id_historico     BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  id_item          INT UNSIGNED     NOT NULL,
  status_anterior  VARCHAR(10)      NULL,
  status_novo      VARCHAR(10)      NOT NULL,
  data_hora        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_bd       VARCHAR(100)     NOT NULL,
  CONSTRAINT pk_historico PRIMARY KEY (id_historico),
  CONSTRAINT fk_historico_item FOREIGN KEY (id_item)
    REFERENCES item_residuo (id_item) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;
