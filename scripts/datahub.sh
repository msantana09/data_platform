#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

NAMESPACE="datahub"
DIR="$BASE_DIR/services/datahub"
CHARTS_DIR="$DIR/charts"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-datahub.yaml"


create_postgresql_secrets() {
    local namespace=$1
    local env_file=$2
    local password=$(get_key_value "$env_file" POSTGRES_PASSWORD)

    create_kubernetes_secret "postgresql-secrets" "$namespace" "--from-literal=postgres-password=$password"
}

start() {
    create_namespace "$NAMESPACE"
    create_postgresql_secrets "$NAMESPACE" "$DIR/.env"

    if ! docker-compose --env-file "$STORAGE_DIR/.env.datahub"  -f "$DOCKER_COMPOSE_FILE" up -d datahub-postgres datahub-elasticsearch-01  &> /dev/null ; then
        echo "Failed to start Datahub's Postgres Database with docker-compose"
        exit 1
    fi 

    helm upgrade --install prerequisites datahub/datahub-prerequisites \
        --values "$CHARTS_DIR/prerequisites-values.yaml" --namespace $NAMESPACE

    # setting a 10 minute timeout for the datahub chart since it does a bunch of checks and upgrades at startup
    helm upgrade --install datahub datahub/datahub \
        --values "$CHARTS_DIR/values.yaml" --namespace $NAMESPACE --timeout 10m

}

# shutdown function
shutdown() {
    app="datahub"
    env_file="$STORAGE_DIR/.env.datahub"

    delete_namespace "$NAMESPACE"

    shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"
}

init(){
    # create .env file if it doesn't exist
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$STORAGE_DIR/.env.datahub"  "$STORAGE_DIR/.env-datahub-template"
}

# Main execution
case $ACTION in
    init|start|shutdown)
        $ACTION
        ;;
    *)
        echo "Error: Invalid action $ACTION"
        exit 1
        ;;
esac