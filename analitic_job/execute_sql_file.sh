#!/bin/bash
set -e

TMP_DIR=$(mktemp -d)
IN_DIR="$TMP_DIR/in"
OUT_DIR="$TMP_DIR/out"
mkdir -p "$IN_DIR" "$OUT_DIR"

declare -a PODMAN_ARGS
declare -A EXPORT_MAP
FILE_COUNTER=0

# Helper function to stage host files into the container's isolated input directory
stage_input_file() {
  local orig_path="$1"
  local basename=$(basename "$orig_path")
  ((FILE_COUNTER++))
  
  # Prefix with a counter to prevent name collisions if multiple files share the same name
  local staged_name="${FILE_COUNTER}_${basename}"
  cp "$orig_path" "$IN_DIR/$staged_name"
  
  # Return the mapped container path
  echo "/app/in/$staged_name"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --sql-file=*)
      ORIG_PATH="${1#*=}"
      STAGED_PATH=$(stage_input_file "$ORIG_PATH")
      PODMAN_ARGS+=("--sql-file=$STAGED_PATH")
      shift
      ;;
    --subst-*)
      ARG_VAL="${1#*=}"
      KEY="${1%%=*}"
      KEY="${KEY#--subst-}"
      
      # If the substitution key ends in PATH, treat the value as an input file
      if [[ "$KEY" == *PATH ]]; then
        STAGED_PATH=$(stage_input_file "$ARG_VAL")
        PODMAN_ARGS+=("--subst-${KEY}=$STAGED_PATH")
      else
        PODMAN_ARGS+=("$1")
      fi
      shift
      ;;
    --export-*)
      KEY_VAL="${1#*=}"
      KEY="${1%%=*}"
      KEY="${KEY#--export-}"
      DEST_PATH="$KEY_VAL"
      
      EXPORT_MAP["$KEY"]="$DEST_PATH"
      PODMAN_ARGS+=("--export-${KEY}=/app/out/${KEY}.csv")
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      shift
      ;;
  esac
done

echo "Starting Podman container..."
podman run --rm \
  -v "$IN_DIR:/app/in:Z" \
  -v "$OUT_DIR:/app/out:Z" \
  spark-sql-runner "${PODMAN_ARGS[@]}"

echo "Container finished. Copying exports to final destinations..."
for KEY in "${!EXPORT_MAP[@]}"; do
  cp "$OUT_DIR/${KEY}.csv" "${EXPORT_MAP[$KEY]}"
  echo "Saved: ${EXPORT_MAP[$KEY]}"
done

rm -rf "$TMP_DIR"
echo "Done."
