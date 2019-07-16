#!/usr/bin/env bash
# coding=utf-8

curl -sfL https://get.k3s.io | sudo sh -
sudo k3s kubectl get node
sudo ./k3s-up.sh

for tries in {1..30}
do
  sleep 5
  output=$(sudo k3s kubectl get services)
  if [[ $(echo "$output" | grep -c NodePort) -eq 2 ]] ; then
    echo "$output"
    # parse string like this. 30805 is the external port
    # pulp-api     NodePort    10.43.170.79   <none>        24817:30805/TCP   0s
    API_PORT=$( echo "$output" | awk -F '[ :/]+' '/pulp-api/{print $6}')
    API_IP=$( echo "$output" | awk -F '[ :/]+' '/pulp-api/{print $3}')
    set -x
    http http://$API_IP:$API_PORT/pulp/api/v3/status/
    set +x
    exit 0
  fi
done
echo "$output"
exit 1
