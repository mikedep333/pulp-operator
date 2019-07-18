#!/usr/bin/env bash
# coding=utf-8

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
sudo kubectl -n local-path-storage logs $STORAGE_POD

for tries in {0..120}; do
  pods=$(sudo kubectl get pods -o wide)
  if [[ $(echo "$pods" | grep -c -v -E "STATUS|Running") -eq 0 ]]; then
    echo "PODS:"
    echo "$pods"
    # I think Travis has the firewall up. For k3s, the host is the
    # 1st/sole node.
    # API_NODE=$( echo "$pods" | awk -F '[ :/]+' '/pulp-api/{print $8}')
    API_NODE="localhost"
    break
  else
    # Often after 30 tries (150 secs), not all of the pods are running yet.
    # Let's keep Travis from ending the build by outputting.
    if [[ $(( tries % 30 )) == 0 ]]; then
      echo "STATUS: Still waiting on pods to transitiion to running state."
      echo "PODS:"
      echo "$pods"
      echo "VOLUMES:"
      sudo kubectl get pvc
      sudo kubectl get pv
      df -h
      sudo kubectl -n local-path-storage get pod
      sudo kubectl -n local-path-storage logs $STORAGE_POD
    fi
    if [[ $tries -eq 120 ]]; then
      echo "ERROR 3: Pods never all transitioned to Running state"
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
sudo kubectl -n local-path-storage logs $STORAGE_POD

URL=http://$API_NODE:$API_PORT/pulp/api/v3/status/
echo "URL:"
echo $URL
# Sometimes 30 tries is not enough for the service to actually come up
# Until it does:
# http: error: Request timed out (5.0s).
for tries in {0..240}; do
  if http --timeout 5 --check-status $URL ; then
    break
  else
    if [[ $tries -eq 120 ]]; then
      echo "ERROR 4: Status page never accessible or returning success"
      exit 4
    fi
  fi
done
