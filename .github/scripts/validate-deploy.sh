#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

source "${SCRIPT_DIR}/validation-functions.sh"

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo "ibmcloud cli not found" >&2
  exit 1
fi

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)
CLUSTERID=$(jq -r '.clusterid // "mykafka"' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

set -e

validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "values.yaml"

check_k8s_namespace "${NAMESPACE}"

# Operator check
check_k8s_resource "${NAMESPACE}" "deployment" "strimzi-cluster-operator-v0.22.1"

# cluster deploy check
check_k8s_resource "${NAMESPACE}" "deployment" "maskafka-entity-operator"

# wait for kafka server job to complete
sleep 1m

# check kafka cluster is in ready state
kafkastatus=$(kubectl get kafkas.kafka.strimzi.io ${CLUSTERID} -n ${NAMESPACE} --no-headers -o custom-columns=":status.conditions[0].type")

count=0
until [[ "${kafkastatus}" = "Ready" ]] || [[ $count -eq 20 ]]; do
  echo "Waiting for ${CLUSTERID} in ${NAMESPACE}"
  count=$((count + 1))
  kafkastatus=$(kubectl get kafkas.kafka.strimzi.io ${CLUSTERID} -n ${NAMESPACE} --no-headers -o custom-columns=":status.conditions[0].type")
  sleep 60
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${CLUSTERID} to become ready in ${NAMESPACE}"
  kubectl get all -n "${NAMESPACE}"
  exit 1
fi

# wait for any cleanup to complete if needed
sleep 1m


cd ..
rm -rf .testrepo
