#!/usr/bin/env bash
# =====================================================================
# EcoCircuito - backup diário do banco (rodar pelo cron às 02:00)
#   0 2 * * * /opt/ecocircuito/scripts/backup.sh
#
# Estratégia:
#  - Backup completo diário com mysqldump (--single-transaction: não trava o banco)
#  - Binary log ligado no servidor para recuperar até o minuto da falha
#  - Mantém 7 diários + 4 semanais; cópia vai para um armazenamento externo
# Usuário de backup deve ter: SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES,
# PROCESS e RELOAD. Senha fica em ~/.my.cnf (permissão 600), nunca no script.
# =====================================================================
set -euo pipefail

DESTINO="/backup/ecocircuito"
DATA=$(date +%Y-%m-%d_%H%M)
ARQUIVO="$DESTINO/diario/ecocircuito_$DATA.sql.gz"

mkdir -p "$DESTINO/diario" "$DESTINO/semanal"

mysqldump --defaults-file="$HOME/.my.cnf" \
  --single-transaction --routines --triggers --events \
  --source-data=2 \
  --databases ecocircuito | gzip > "$ARQUIVO"

# confere se o arquivo não está corrompido
gzip -t "$ARQUIVO"

# domingo: guarda uma cópia semanal
if [ "$(date +%u)" -eq 7 ]; then
  cp "$ARQUIVO" "$DESTINO/semanal/"
fi

# retenção: 7 dias para diários, 28 dias para semanais
find "$DESTINO/diario"  -name '*.sql.gz' -mtime +7  -delete
find "$DESTINO/semanal" -name '*.sql.gz' -mtime +28 -delete

# cópia para fora do servidor (ex.: bucket na nuvem)
# rclone copy "$ARQUIVO" remoto:ecocircuito-backup/

echo "Backup OK: $ARQUIVO"
