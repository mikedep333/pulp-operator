#!/bin/bash

# TODO: Check if all of these are needed.
# TODO: Check if these should only ever be run once; or require
# special logic to update
kubectl apply -f deploy/crds/pulpproject_v1alpha1_pulp_crd.yaml
kubectl apply -f deploy/crds/pulpproject_v1alpha1_pulp_cr.yaml

if [[ -e deploy/pulp-operator.config-map.yml ]]; then
  kubectl apply -f deploy/pulp-operator.config-map.yml
elif [[ "$TRAVIS" == "true" ]]; then
  kubectl apply -f deploy/pulp-operator.travis.config-map.yml
elif [[ "$(hostname)" == "pulp-demo"* ]]; then
  kubectl apply -f deploy/pulp-operator.pulp-demo.config-map.yml
else
  kubectl apply -f deploy/pulp-operator.default.config-map.yml
fi
kubectl apply -f deploy/pulp-operator.config-map.yml
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml
kubectl apply -f deploy/operator.yaml
