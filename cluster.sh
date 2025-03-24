#!/bin/bash

if [ $# -lt 4 ]; then
    echo "Usage: $0 docker_image head_node_address --master|--worker path_to_hf_home [additional_args...]"
    exit 1
fi

DOCKER_IMAGE="$1" # vllm/vllm-openai
HEAD_NODE_ADDRESS="$2"
NODE_TYPE="$3"  # Should be --master or --worker
PATH_TO_HF_HOME="$4"
shift 4

# Additional arguments are passed directly to the Docker command
ADDITIONAL_ARGS=("$@")

# Validate node type
if [ "${NODE_TYPE}" != "--master" ] && [ "${NODE_TYPE}" != "--worker" ]; then
    echo "Error: Node type must be --master or --worker"
    exit 1
fi

# Define a function to cleanup on EXIT signal
cleanup() {
    docker stop node
    docker rm node
}
trap cleanup EXIT

# Build ray commandline
RAY_START_CMD="ray start --block"
if [ "${NODE_TYPE}" == "--master" ]; then
    RAY_START_CMD+=" --master --port=6379"
else
    RAY_START_CMD+=" --address=${HEAD_NODE_ADDRESS}:6379"
fi

docker run \
    --entrypoint /bin/bash \
    --network host \
    --name node \
    --shm-size 10.24g \
    --gpus all \
    -v "${PATH_TO_HF_HOME}:/root/.cache/huggingface" \
    "${ADDITIONAL_ARGS[@]}" \
    "${DOCKER_IMAGE}" -c "${RAY_START_CMD}"

# bash run_cluster.sh \
#     biznetgio/vllm \
#     ip_of_master_node \
#     --master \
#     /huggingface/path \
#     -e VLLM_HOST_IP=ip_of_this_node

# bash run_cluster.sh \
#     biznetgio/vllm \
#     ip_of_master_node \
#     --worker \
#     /huggingface/path \
#     -e VLLM_HOST_IP=ip_of_this_node