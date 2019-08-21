# DEPRECATED SEE https://github.com/voor/kubernetes-lb

# Creating a Load Balancer for a new Kubernetes Cluster created with PKS.

Since there is no automated way to add a Load Balancer to the front of a PKS created cluster, this is an ease-of-use module to help.

This script is mostly automated, and can be found at `terraforming-k8s/configure-api`, but requires a few things installed and working.

## Prerequisites

You need the following installed and working:

1. You need to have run the `terraforming-pks` package, since this script relies on the `terraform.tfstate` that is output from that process.
1. Create a `terraform.tfvars`, which includes the following:
    ```
    access_key         = "<>"
    secret_key         = "<>"
    region             = "us-east-1"
    ```
1. `terraform`
1. `jq`
1. `om`
1. `pks`
1. `ssh`

## Usage

```
./configure-api ${CLUSTER_NAME} ${OM_USERNAME} ${OM_PASSWORD}
terraform apply "pcf.tfplan"
```

Example:

Given a cluster with the name `dev` and an Ops Manager instance with a username of `admin` and password of `password1` you would run the following:

```
./configure-api dev admin password1
terraform apply "pcf.tfplan"
```
