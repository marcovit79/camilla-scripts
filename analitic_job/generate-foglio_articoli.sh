#!/bin/bash
set -e

DO_CHECKS=false
for arg in "$@"; do
  case $arg in
    --do-checks)
      DO_CHECKS=true
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SQL_DIR="${SCRIPT_DIR}/sql"
MEXAL_EXPORT_DIR="${SCRIPT_DIR}/export_files"
RESULTS_DIR="${SCRIPT_DIR}/results"

mkdir -p "${RESULTS_DIR}"

podman build -t spark-sql-runner "${SCRIPT_DIR}"

ARGS=(
  "--sql-file=${SQL_DIR}/compute_foglio_articoli.sql"
  "--subst-ALIAS_CSV_PATH=${MEXAL_EXPORT_DIR}/alias.csv"
  "--subst-ARTICOLI_1_CSV_PATH=${MEXAL_EXPORT_DIR}/articoli_1.csv"
  "--subst-ARTICOLI_5_CSV_PATH=${MEXAL_EXPORT_DIR}/articoli_5.csv"
  "--subst-FORNITORI_CSV_PATH=${MEXAL_EXPORT_DIR}/fornitori.csv"
  "--export-foglio_articoli=${RESULTS_DIR}/foglio_articoli.csv"
)

if [ "$DO_CHECKS" = true ]; then
  ARGS+=(
    "--sql-file=${SQL_DIR}/check_foglio_articoli.sql"
    "--subst-FOGLIO_ARTICOLI_FROM_DRIVE_CSV_PATH=${BASE_MEXAL_EXPORT_DIR}/foglio_articoli_da_drive_2026_03_01.csv"
  )
fi

"${SCRIPT_DIR}/execute_sql_file.sh" "${ARGS[@]}"


