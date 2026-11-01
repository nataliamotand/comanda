#!/usr/bin/env bash
# Recarrega tudo num Postgres local (teste). Uso: ./reload.sh "psql <conexão>"
set -e
P=${1:-"psql -h /var/tmp/pgtest -p 5433 -U postgres"}
P="$P -q -v ON_ERROR_STOP=1"
python3 data/generate.py
$P -f db/01_schema.sql 2>/dev/null
for t in restaurantes pratos promocoes pedidos itens_pedido despesas repasses; do
  $P -c "\copy public.$t from 'data/out/$t.csv' with (format csv, header true, null '')"
done
$P -f db/03_views.sql
