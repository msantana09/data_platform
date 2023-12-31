#!/bin/bash

apps=("minio" "hive" "trino" "airflow" "spark" "kubernetes-dashboard" "kafka")

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

delete_data_option=""

if [[ "$ACTION" == "shutdown" ]] && [[ "$DELETE_DATA" == true ]]; then
    delete_data_option="--delete-data"
fi

for app in "${apps[@]}"; do
    script=("$BASE_DIR/scripts/$app.sh")

    run_script "$script" "$ACTION" -b "$BASE_DIR" -c "$CLUSTER" "$delete_data_option"
done