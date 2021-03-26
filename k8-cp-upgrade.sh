
#!/bin/bash
# Upgrading K8s Control plane to latest stable 1.20 version
# Author:    Newton Costa
# Repo:      github.com/NewtonCosta/k8s-cp-upgrade-script
# Create on: 2021-03-26

# NOTE: The upgrade procedure on control plane nodes should be executed one node at a time. 
#       Pick a control plane node that you wish to upgrade first

# Global variables
NODE_NAME=${1:-$HOSTNAME}
KUBEADM_VERSION="1.20.2-00"

echo -e "Starting upgrade...\n"

# Draining control plane. Prepare the node for maintenance by marking it unschedulable and evicting the workloads
# You have to enter your node name as a parameter when invoking the script, otherwise it will use the value of HOSTNAME environment variable
echo -e "> Draining control plane \e[1m${NODE_NAME}\e[0m \n"
sudo kubectl drain ${NODE_NAME} --ignore-daemonsets
echo
#
# Upgrading Kubeadm and showing the new version
echo -e "> Upgrading kubeadm...\n"
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm=${KUBEADM_VERSION} && sudo apt-mark hold kubeadm
echo  "Upgraded to version: `sudo kubeadm version`"
echo
#
# Verifying upgrade plan
echo -e "> Checking upgrade plan...\n"
sudo kubeadm upgrade plan ${KUBEADM_VERSION}
#
# Applying the upgrade
echo -e "> Aplying the upgrade ignoring automatic certificate renewal...\n"
sudo kubeadm upgrade apply ${KUBEADM_VERSION} --certificate-renewal=false
#
# Upgrade kubelet and kubectl
echo -e "> Upgrading kubelet and kubectl\n"
sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet=${KUBEADM_VERSION}  kubectl=${KUBEADM_VERSION}  && sudo apt-mark hold kubelet kubectl
echo
#
# Restarting the kubelet
sudo systemctl daemon-reload && sudo systemctl restart kubelet
echo -e "daemon reloaded and kubelet restarted\n"
#
# Uncordoning the node
echo -e "> Bring the node back online by marking it schedulable...\n"
kubectl uncordon ${NODE_NAME}
echo
#
echo -e "Control plane ${HOSTNAME} \e[32msuccessfuly\e[0m upgraded"
