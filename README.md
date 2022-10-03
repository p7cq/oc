# Nextcloud in Kubernetes using Terraform and OCI

## Overview

A project for migrating my home Nextcloud instance to a private Kubernetes cluster in Oracle Cloud Infrastructure.

## Cloud resources used

I used the following OCI resources:

```
Identity & Security
    Compartments
    Vaults
Networking
    Virtual Cloud Network
        Subnets
        Route Tables
        Dynamic Routing Gateways Attachments*
        Internet Gateways
        Security Lists
        NAT Gateways
        Service Gateways
    Reserved Public IPs
    Load Balancers
Developer Services
    Kubernetes Clusters (OKE)
Storage
    Object Storage & Archive Storage
        Buckets
```

 \* *Plumbing for other components I have in compartment; not strictly needed, but see **Control Plane connectivity** below.*

A dedicated OCI group and user managing the project's resources was created and given the necessary permissions. I used the project name as the group name.

```
allow group oc to read all-resources in tenancy
allow group oc to manage all-resources in compartment id ocid1.compartment.oc1..project.compartment
```

To configure the development environment, an *API key* and a *Customer Secret Key* must be generated for the OCI user.

### OCI resources not managed by Terraform

The following resources must exist before provisioning:

- a `Compartment` - where all the project resources are created
- a `Vault` - with various secrets used throughout the project
- a `Bucket` - to store the state using Terraform' s  `S3` backend

## Development environment

`Windows`, `Windows Terminal`, `WSL` with `Oracle Linux`, `OCI CLI`, `kubectl`, `Terraform`, `IntelliJ IDEA (Community Edition)` with `Terraform and HCL` plugin.

### Development environment configuration

The `terraform` command used is embedded into a `bash` alias:

```bash
$ alias tf='TF_VAR_fingerprint=<fingerprint> TF_VAR_private_key_path=~/.ssh/<private API key>.pem TF_VAR_region=<region> TF_VAR_tenancy_ocid=<tenancy OCID> TF_VAR_user_ocid=<user OCID> AWS_ACCESS_KEY_ID=<access key> AWS_SECRET_ACCESS_KEY=<secret key> ~/.local/bin/terraform'
```

Create a bucket named `oc` using the OCI console.

Rename `oc.backend.example` to `oc.backend`, modify `endpoint` and `region` with the correct bucket namespace and region then initialize Terraform:

```bash
$ tf init -backend-config=oc.backend
$ tf workspace new oc
```

## Vaults & secrets

All users, passwords, keys and other private data is stored in a vault named `oc`, which contains the following secrets:

- `oc` - contains main Nextcloud configuration (has the same name as the vault)
- `oke-worker-ssh-public` - the SSH public key deployed on Kubernetes nodes
- `oke-worker-ssh-private` - the SSH private key deployed on Kubernetes nodes
- `bastion-ssh-public` - the SSH public key deployed on bastion
- `bastion-ssh-private` - the SSH private key deployed on bastion

The OCI secret used in Nextcloud deployment contains a JSON object with the following structure:

```json
{
    "mysql-admin-password":      "MySQL root password",
    "mysql-nc-user":             "MySQL Nextcloud user",
    "mysql-nc-password":         "MySQL Nextcloud password",
    "nc-user":                   "Nextcloud administrator user",
    "nc-password":               "Nextcloud administrator password",
    "nc-smtp-host":              "Nextcloud SMTP host",
    "nc-smtp-mail-domain":       "Nextcloud SMTP mail domain",
    "nc-smtp-mail-from-address": "Nextcloud mail from address",
    "nc-smtp-user":              "Nextcloud administrator email user",
    "nc-smtp-password":          "Nextcloud administrator email password",
    "redis-password":            "Redis password"
}
```

## Provisioning

Rename `oc.json.example` to `oc.json` and modify it.

The `kubernetes` parameter must be set to `false` when provisioning for the first time.

Apply configuration with

```bash
$ tf apply
```

Create directory `~/.kube` and copy over the generated `kubeconfig` file:

```bash
$ mkdir ~/.kube
$ cp artifacts/kube.config ~/.kube/config
$ chmod 600 ~/.kube/config
```

To provision Kubernetes components, modify `kubernetes` to `true` in `oc.json` and run `tf apply` again.

**Note**: the second `apply` will fail if there is no connectivity between development machine and the Control Plane.

### Control Plane connectivity

Control plane connectivity can be also established using an SSH tunnel and a modified `kube.config` file. 

To use this option, in `oc.json` set `enabled` to `true` and configure the remainder of the `bastion` section according to local environment.
