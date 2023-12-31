#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"


NAMESPACE="hive"
IMAGE_REPO="custom-apache-hive"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/hive"
MANIFESTS_DIR="$DIR/manifests"
STORAGE_DIR="$BASE_DIR/services/storage"
DOCKER_COMPOSE_FILE="$STORAGE_DIR/docker-compose-hive.yaml"


start() {
    create_namespace "$NAMESPACE"    
    
    local env_file="$DIR/.env"
    create_kubernetes_secret "hive-secrets" "$NAMESPACE" "--from-env-file=$env_file" 

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d &> /dev/null ; then
        echo "Failed to start Hive's Postgres Database with docker-compose"
        exit 1
    fi 
    
    sleep 5;
    
    kubectl apply -f "$MANIFESTS_DIR/configMap.yaml" \
    -f "$MANIFESTS_DIR/service.yaml" \
    -f "$MANIFESTS_DIR/deployment.yaml"

    wait_for_container_startup "$NAMESPACE"  hive-metastore app=hive-metastore

    # check if hive has started already
    if ! kubectl -n hive logs "$(kubectl -n hive get pods -l app=hive-metastore -o jsonpath='{.items[0].metadata.name}')" | grep  "Starting Hive Metastore Server" &> /dev/null ; then
        # tail the logs of the container with label app=hive-metastore in the namespace hive, 
        # and exit once the string "Starting Hive Metastore Server" is found.
        echo "Waiting for Hive initialization to complete..."
        kubectl -n hive logs -f "$(kubectl -n hive get pods -l app=hive-metastore -o jsonpath='{.items[0].metadata.name}')" | grep -q "Starting Hive Metastore Server"
    fi
}

# shutdown function
shutdown() {

    local app="hive"
    local env_file="$STORAGE_DIR/.env.$app"
    delete_namespace "$NAMESPACE"

    shutdown_docker_compose_stack "$app" "$env_file" "$DELETE_DATA" "$DOCKER_COMPOSE_FILE"
}

init(){
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    create_env_file "$STORAGE_DIR/.env.hive"  "$STORAGE_DIR/.env-hive-template"
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