#!/usr/bin/env bash
# coding=utf-8

curl -sfL https://get.k3s.io | sudo sh -
sudo k3s kubectl get node
sudo ./k3s-up.sh

for tries in {1..30}
do
  sleep 5
  pods=$(sudo k3s kubectl get pods --all-namespaces)
  if [[ echo "$pods" | grep Pending ]] ; then
    services=$(sudo k3s kubectl get services)
    echo "SERVICES:"
    echo "$services"
    echo "PODS:"
    echo "$pods"

    # parse string like this. 30805 is the external port
    # pulp-api     NodePort    10.43.170.79   <none>        24817:30805/TCP   0s
    API_PORT=$( echo "$services" | awk -F '[ :/]+' '/pulp-api/{print $6}')
    API_IP=$( echo "$services" | awk -F '[ :/]+' '/pulp-api/{print $3}')

    if [[ $(echo "$services" | grep -c NodePort) -lt 2 ]]; then
      exit 1
    fi

    URL=http://$API_IP:$API_PORT/pulp/api/v3/status/
    echo $URL

    for tries in {1..30}
    do
      if http --timeout 5 --check-status $URL ; then
        exit 0
    fi
    done
  fi
done # If the pods never became available
echo "SERVICES:"
echo "$services"
echo "PODS:"
echo "$pods"
exit 1
