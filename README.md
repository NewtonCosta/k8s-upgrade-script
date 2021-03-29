# Upgrading K8s Control Plane and Workers via Bash Sript

> ### Before begin upgrade:
> - Make sure you read the release notes carefully.
> - The cluster should use a static control plane and etcd pods or external etcd.
> - Make sure to back up any important components, such as app-level state stored in a database.
> _kubeadm upgrade does not touch your workloads, only components internal to Kubernetes, but backups are always a best practice._
> - [Swap must be disabled](https://serverfault.com/questions/684771/best-way-to-disable-swap-in-linux)
> - It's recommended to determine which version to upgrade to, check the procedure [here](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/#determine-which-version-to-upgrade-to)

### Installation
1. just copy the file [_k8-cp-upgrade.sh_](https://github.com/NewtonCosta/k8s-upgrade-script/blob/main/k8-cp-upgrade.sh) to your machine
2. Change permission ``` chown +x k8-cp-upgrade.sh ```

<hr>

### _Example: upgrading k8s control plane to latest stable 1.20.2 version_

```bash
#!/bin/bash
# Upgrading K8s Control plane to latest stable 1.20 version
# Author:    Newton Costa
# Repo:      github.com/NewtonCosta/k8s-cp-upgrade-script
# Create on: 2021-03-26

# NOTE: The upgrade procedure on control plane nodes should be executed one node at a time. Pick a control plane node that you wish to upgrade first

# Global variables
NODE_NAME=${1:-$HOSTNAME}
KUBEADM_VERSION="1.20.2"

echo -e "Starting upgrade...\n"

# Draining control plane. Prepare the node for maintenance by marking it unschedulable and evicting the workloads
# You have to enter your node name as a parameter when invoking the script, otherwise it will use the value of HOSTNAME environment variable
echo -e "> Draining control plane \e[1m${NODE_NAME}\e[0m \n"
sudo kubectl drain ${NODE_NAME} --ignore-daemonsets
echo
#
# Upgrading Kubeadm and showing the new version
echo -e "> Upgrading kubeadm...\n"
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm="${KUBEADM_VERSION}-00" && sudo apt-mark hold kubeadm
echo  "Upgraded to version: `sudo kubeadm version`"
echo
#
# Verifying upgrade plan
echo -e "> Checking upgrade plan...\n"
sudo kubeadm upgrade plan "v${KUBEADM_VERSION}"
#
# Applying the upgrade
echo -e "> Aplying the upgrade ignoring automatic certificate renewal...\n"
sudo kubeadm upgrade apply "v${KUBEADM_VERSION}" --certificate-renewal=false --yes
echo
#
# Upgrade kubelet and kubectl
echo -e "> Upgrading kubelet and kubectl\n"
sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet="${KUBEADM_VERSION}-00"  kubectl="${KUBEADM_VERSION}-00"  && sudo apt-mark hold kubelet kubectl
echo
#
# Restarting the kubelet
sudo systemctl daemon-reload && sudo systemctl restart kubelet
echo -e "daemon reloaded and kubelet restarted\n"
#
# Uncordoning the node
echo -e "> Bring the node back online by marking it schedulable...\n"
kubectl uncordon ${NODE_NAME}

#
echo -e "\nControl plane ${HOSTNAME} \e[32msuccessfuly\e[0m upgraded\n"
```
<hr>

### _Example: upgrading k8s control plane to latest stable 1.20 version_



**Note:** After upgrade procedure all containers are restarted, because the container spec hash value is changed.


[Official documentation: ](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)








