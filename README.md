# LHIND-Challenge
Automation with Terraform and Ansible to deploy a Kubernetes cluster with Helm and deploy Jenkins application inside the cluster


## **The Challenge**

1-Use Terraform to deploy infrastructure in Azure/AWS ( Linux Images, 3 VMs)

2-Deploy and Configure A Kubernetes Cluster 1Master-2Worker using Ansible ( do NOT use the kubernetes service provided by the cloud provider). Deploy this cluster within the provisioned infrastructure with Terraform. Run the Ansible role during Terraform Run

3-Install and Configure Jenkins inside Kubernetes using Helm


## **Project Flow**

> The whole project is done by running the terraform main file (main.tf) with command:
  terraform apply --auto-approve

Terraform main file creates 3 VMS in Azure Cloud with respective networks. After that installs Kubernetes in all three VMs. On top of Kubernetes it installs helm, with which installs Jenkins as an application inside the Kubernetes cluster.

> Ansible is used to install the followings:
- master.yml: Installs, configures and initializes Kubernetes cluster on the Master node
- node.yml: Installs configures and joins the worker nodes to the Kubernetes Cluster
- helm.yml installs and configures Helm in the Kubernetes cluster and uses it to deploy Jenkins in the cluster
