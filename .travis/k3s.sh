#!/usr/bin/env bash
# coding=utf-8

curl -sfL https://get.k3s.io | sudo sh -
sudo k3s kubectl get node
sudo ./k3s-up.sh

for tries in {1..30}
do
  sleep 5
  if [[ $(sudo k3s kubectl get services | grep -c NodePort) -eq 2 ]] ; then
    sudo k3s kubectl get services
    exit 0
  fi
done
exit 1
