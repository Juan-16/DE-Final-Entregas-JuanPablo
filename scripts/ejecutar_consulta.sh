#!/usr/bin/env bash
# Ejecuta UNA sentencia SQL en Athena (workgroup del ejercicio), espera a que termine,
# descarga el CSV de resultados desde resultados-athena/ y registra la ejecución en
# evidencias/ejecuciones_athena.csv (etapa, archivo_sql, id_ejecucion, archivo_resultado).
#
# Uso (desde la raíz del repositorio):
#   bash scripts/ejecutar_consulta.sh <etapa> <archivo_sql> <archivo_resultado> [n_sentencia]
#     etapa             inicial | final
#     archivo_sql       ruta relativa, p. ej. consultas/intentos_por_fecha_estado.sql
#     archivo_resultado ruta relativa, p. ej. resultados/inicial/intentos_por_fecha_estado.csv
#     n_sentencia       número de la sentencia dentro del archivo (por defecto 1)
#
# Requiere: AWS CLI v2 con credenciales y Terraform ya aplicado en infraestructura/.
set -euo pipefail

if [ $# -lt 3 ]; then
  sed -n '2,13p' "$0"; exit 1
fi

ETAPA="$1"; SQL_FILE="$2"; RESULTADO="$3"; N="${4:-1}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

case "$ETAPA" in inicial|final) ;; *) echo "La etapa debe ser 'inicial' o 'final'" >&2; exit 1 ;; esac
[ -f "$SQL_FILE" ] || { echo "No existe $SQL_FILE" >&2; exit 1; }

# Datos del despliegue (outputs de Terraform)
WORKGROUP=$(terraform -chdir=infraestructura output -raw workgroup)
BASE_DATOS=$(terraform -chdir=infraestructura output -raw base_datos)
REGION=$(terraform -chdir=infraestructura output -raw region)

# Extrae la sentencia N: quita comentarios "--" de línea completa y separa por ";"
SQL=$(grep -v '^[[:space:]]*--' "$SQL_FILE" | awk -v n="$N" 'BEGIN{RS=";"} {gsub(/^[[:space:]]+|[[:space:]]+$/, "")} length($0)>0 {i++; if (i==n) {print; exit}}')
[ -n "$SQL" ] || { echo "No se encontró la sentencia $N en $SQL_FILE" >&2; exit 1; }

echo ">> [$ETAPA] $SQL_FILE (sentencia $N) en workgroup $WORKGROUP"
ID=$(aws athena start-query-execution \
  --region "$REGION" \
  --work-group "$WORKGROUP" \
  --query-execution-context "Database=$BASE_DATOS" \
  --query-string "$SQL" \
  --query QueryExecutionId --output text)
echo "   id_ejecucion: $ID"

while true; do
  ESTADO=$(aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
    --query QueryExecution.Status.State --output text)
  case "$ESTADO" in
    SUCCEEDED) break ;;
    FAILED|CANCELLED)
      aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
        --query QueryExecution.Status.StateChangeReason --output text >&2
      exit 1 ;;
    *) sleep 1 ;;
  esac
done

SALIDA_S3=$(aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
  --query QueryExecution.ResultConfiguration.OutputLocation --output text)
ESCANEADO=$(aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
  --query QueryExecution.Statistics.DataScannedInBytes --output text)

# Athena entrega el CSV con todos los valores entre comillas; los datos no contienen
# comas ni comillas internas, así que se quitan para dejar el mismo formato de las referencias.
mkdir -p "$(dirname "$RESULTADO")"
aws s3 cp --region "$REGION" "$SALIDA_S3" - --quiet | tr -d '"' | tr -d '\r' > "$RESULTADO"

REGISTRO=evidencias/ejecuciones_athena.csv
mkdir -p evidencias
[ -s "$REGISTRO" ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$REGISTRO"
echo "$ETAPA,$SQL_FILE,$ID,$RESULTADO" >> "$REGISTRO"

echo "   resultado S3: $SALIDA_S3  (bytes escaneados: $ESCANEADO)"
echo "   guardado en:  $RESULTADO"
cat "$RESULTADO"
echo
