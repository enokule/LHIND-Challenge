# LHIND-Challenge
Automation with Terraform and Ansible to deploy a Kubernetes cluster with Helm and deploy Jenkins application inside the cluster


## **The Challenge**

1-Use Terraform to deploy infrastructure in Azure/AWS ( Linux Images, 3 VMs)

2-Deploy and Configure A Kubernetes Cluster 1Master-2Worker using Ansible ( do NOT use the kubernetes service provided by the cloud provider). Deploy this cluster within the provisioned infrastructure with Terraform. Run the Ansible role during Terraform Run

3-Install and Configure Jenkins inside Kubernetes using Helm


## **Project Flow**

> The whole project is done by running the terraform main file (main.tf) with command:
  ```
  terraform apply --auto-approve
  ```
Terraform main file creates 3 VMS in Azure Cloud with respective networks. After that installs Kubernetes in all three VMs. On top of Kubernetes it installs helm, with which installs Jenkins as an application inside the Kubernetes cluster.

> Ansible is used to install the followings:
- master.yml: Installs, configures and initializes Kubernetes cluster on the Master node
- node.yml: Installs configures and joins the worker nodes to the Kubernetes Cluster
- helm.yml installs and configures Helm in the Kubernetes cluster and uses it to deploy Jenkins in the cluster
__Note: Ansible is run within the terraform in the main.tf file using null_resources (master_ansible, nodes_ansible, helm-jenkins-setup) with the below CLI command (nodes example):__
```
ansible-playbook -u admin_user -i '${element(azurerm_linux_virtual_machine.node.*.public_ip_address, count.index)}', --private-key ${var.ssh_key_private} --become-method=sudo -b --become-user=root /root/lh-azure-cluster/ansible/nodes.yml
```

> providers.tf imports Azure as the provider for Terraform
> variables.tf imports two variables: private and public SSH keys (id_rsa and id_rsa.pub)

> Jenkins folder contains the needed folders for deploying Jenkins in Kubernetes with Helm:
- jenkins-sa.yaml: creates a service account for Jenkins in the "jenkins" namespace in Kubernetes cluster
- jenkins-volume.yaml: creates a volume for jenkins which is mounted in /data/jenkins-volume/ in the nodes
- jenkins-values.yaml: contains the values for the helm chart

> The folders "docker" and "agent" are used to create a jenkins docker image with docker installed inside, but it's not working properly

## **Resources**

- https://docs.microsoft.com/en-us/azure/developer/terraform/create-linux-virtual-machine-with-infrastructure
- https://www.jenkins.io/doc/book/installing/kubernetes/
- https://medium.com/@karthikeyan_krishnaswamy/setting-up-a-kubernetes-cluster-on-ubuntu-18-04-4a89c74420f9
