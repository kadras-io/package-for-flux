#!/usr/bin/env bash
#
# Removes what uninstalling the package leaves behind on purpose: the Flux resources, their CustomResourceDefinitions,
# and the namespace. The finalizers are removed first, since the controllers aren't running anymore to handle them.
#
#   ../cleanup.sh <flux-namespace>

set -eo pipefail

for crd in $(kubectl get crds -l app.kubernetes.io/part-of=flux -o jsonpath='{.items[*].metadata.name}'); do
  kubectl get "$crd" -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
    while read -r namespace name; do
      kubectl patch "$crd" "$name" -n "$namespace" --type=merge -p '{"metadata":{"finalizers":null}}'
    done
done
kubectl delete crds -l app.kubernetes.io/part-of=flux --wait
kubectl delete namespace "$1" --wait
