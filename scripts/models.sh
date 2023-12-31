#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

source "$SCRIPT_DIR/helper_functions/entry.sh" "$@"
source "$SCRIPT_DIR/helper_functions/common.sh"

NAMESPACE="models"
IMAGE_REPO="model-api"
IMAGE_TAG="latest"
DIR="$BASE_DIR/services/models"
MANIFESTS_DIR="$DIR/manifests"

install() {
    local dir=$1
    local namespace=$2

    kubectl apply  -f "$MANIFESTS_DIR/service.yaml" \
    -f "$MANIFESTS_DIR/ingress.yaml" \
    -n "$NAMESPACE"

    # run init job
    kubectl apply -f "$MANIFESTS_DIR/deployment-init.yaml" -n "$namespace"

    # run deployment-init.yaml and wait for it to complete before running main deployment
    if ! kubectl wait --for=condition=complete --timeout=600s job/model-api-init -n "$namespace" ; then
        echo "WARNING: Model API initialization job failed"
    else
        echo "Model API initialization job completed"

        # remove the completed job container
        kubectl delete job/model-api-init -n "$namespace"
        # run main deployment
        kubectl apply -f "$MANIFESTS_DIR/deployment.yaml" -n "$namespace"
    fi
}

start() {
    create_namespace "$NAMESPACE"

    create_kubernetes_secret "env-secrets" "$NAMESPACE"  "--from-env-file=$DIR/.env"

    # Build custom image and load it into the cluster
    if ! build_and_load_image "$DIR" "$IMAGE_REPO" "$IMAGE_TAG" ; then
        echo "Failed to load image to local registry"
        exit 1
    fi

    install "$DIR" "$NAMESPACE"
}

# Shutdown function
shutdown() {
   delete_namespace "$NAMESPACE"
}


init(){
    create_env_file "$DIR/.env"  "$DIR/.env-template"
    mkdir -p "$DIR/data"
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