#!/usr/bin/env bash
# coding=utf-8

curl -sfL https://get.k3s.io | sudo sh -
sudo kubectl get node
# By default, k3s lacks a storage class.
# https://github.com/rancher/k3s/issues/85#issuecomment-468293334
# This is the way to add a simple hostPath storage class.
sudo kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

sudo ./k3s-up.sh

# Once the services are both up, the pods will be in a Pending state.
# Before the services are both up, the pods may not exist at all.
# So check for the services being up 1st.
for tries in {0..30}; do
  services=$(sudo kubectl get services)
  if [[ $(echo "$services" | grep -c NodePort) -eq 2 ]]; then
    # parse string like this. 30805 is the external port
    # pulp-api     NodePort    10.43.170.79   <none>        24817:30805/TCP   0s
    API_PORT=$( echo "$services" | awk -F '[ :/]+' '/pulp-api/{print $6}')
    API_IP=$( echo "$services" | awk -F '[ :/]+' '/pulp-api/{print $3}')
    echo "SERVICES:"
    echo "$services"
    break
  else
    if [[ $tries -eq 30 ]]; then
      echo "ERROR 2: 1 or more external services never came up"
      echo "SERVICES:"
      echo "$services"
      exit 2
    fi
  fi
  sleep 5
done   

sudo kubectl -n local-path-storage get pod
STORAGE_POD=$(sudo kubectl -n local-path-storage get pod | awk '/local-path-provisioner/{print $1}')

echo "VOLUMES:"
sudo kubectl get pvc
sudo kubectl get pv
df -h
sudo kubectl -n local-path-storage get pod
sudo kubectl -n local-path-storage logs -f $STORAGE_POD

for tries in {0..60}; do
  pods=$(sudo kubectl get pods)
  if [[ $(echo "$pods" | grep -c Pending) -eq 0 ]]; then
    echo "PODS:"
    echo "$pods"
    break
  else
    if [[ $tries -eq 30 ]]; then
      echo "ERROR 3: Pods never all transitioned to Running state"
      echo "PODS:"
      echo "$pods"
      echo "VOLUMES:"
      sudo kubectl get pvc
      sudo kubectl get pv
      df -h
      sudo kubectl -n local-path-storage get pod
      sudo kubectl -n local-path-storage logs -f $STORAGE_POD
      exit 3
    fi
  fi
  sleep 5
done

echo "VOLUMES:"
sudo kubectl get pvc
sudo kubectl get pv
df -h
sudo kubectl -n local-path-storage get pod
sudo kubectl -n local-path-storage logs -f $STORAGE_POD

URL=http://$API_IP:$API_PORT/pulp/api/v3/status/
echo "URL:"
echo $URL
for tries in {0..30}; do
  if http --timeout 5 --check-status $URL ; then
    break
  else
    if [[ $tries -eq 30 ]]; then
      echo "ERROR 4: Status page never accessible or returning success"
      exit 4
    fi
  fi
done
