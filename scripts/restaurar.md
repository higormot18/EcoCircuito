# Como restaurar o banco EcoCircuito

## 1. Restaurar o último backup completo

```bash
gunzip < /backup/ecocircuito/diario/ecocircuito_AAAA-MM-DD_0200.sql.gz | mysql -u admin_eco -p
```

## 2. Recuperar até o minuto antes da falha (point-in-time)

O cabeçalho do dump mostra em qual binary log e posição o backup parou
(linha `CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE=..., SOURCE_LOG_POS=...`).

```bash
mysqlbinlog --start-position=POSICAO_DO_DUMP \
            --stop-datetime="AAAA-MM-DD HH:MM:SS" \
            /var/lib/mysql/binlog.0000XX | mysql -u admin_eco -p
```

## 3. Conferir

```sql
USE ecocircuito;
SELECT COUNT(*) FROM item_residuo;
SELECT MAX(data_entrega) FROM entrega;
```

## Metas
- **RPO** (quanto de dado podemos perder): até 5 minutos, com os binary logs copiados a cada 5 minutos para o armazenamento externo.
- **RTO** (quanto tempo para voltar): até 1 hora.
- Teste de restauração: uma vez por mês, em servidor separado.
