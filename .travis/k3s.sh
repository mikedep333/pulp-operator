#!/usr/bin/env bash
# coding=utf-8

curl -sfL https://get.k3s.io | sudo sh -
sudo k3s kubectl get node
sudo ./k3s-up.sh
alias kubectl="sudo k3s kubectl"

# Once the services are both up, the pods will be in a Pending state.
# Before the services are both up, the pods may not exist at all.
# So check for the services being up 1st.
for tries in {0..30}; do
  services=$(kubectl get services)
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

echo "VOLUMES:"
kubectl get pvc

for tries in {0..30}; do
  pods=$(kubectl get pods)
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
      kubectl get pvc
      exit 3
    fi
  fi
  sleep 5
done

echo "VOLUMES:"
kubectl get pvc

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
