#!/usr/bin/env bash
# coding=utf-8

# This is their convenience installer script.
# Does a bunch of stuff, such as setting up a `kubectl` -> `k3s kubectl` symlink.
curl -sfL https://get.k3s.io | sudo sh -
sudo kubectl get node
# By default, k3s lacks a storage class.
# https://github.com/rancher/k3s/issues/85#issuecomment-468293334
# This is the way to add a simple hostPath storage class.
sudo kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
sudo kubectl get storageclass
# How make it the default StorageClass
sudo kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
sudo kubectl get storageclass

echo "NAT"
sudo iptables -L -t nat
echo "IPTABLES"
sudo iptables -L
echo "UFW"
sudo ufw status verbose
sudo "CLUSTER-INFO"
sudo kubectl cluster-info
