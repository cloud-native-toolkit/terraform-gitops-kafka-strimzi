#  Kafka - Strimzi gitops terraform module
This module deploys Strimzi Kafka into a given namespace on OpenShift.  There are two configurations that are supplied, a large and small deployment which should suffice for most deployments. Set the variable `kafka_size` accordingly.  If a default password is not supplied when calling this module, then a random password will be created.  Set the `user_name` and `user_password` to not use the defaults.


Block storage on the cluster is also required. Set the `storageclass` varible to the preferred block storage class.

## Supported platforms

- OCP 4.8+

## Suggested companion modules

The module itself requires some information from the cluster and needs a
namespace to be created. The following companion
modules can help provide the required information:

- Gitops:  github.com/cloud-native-toolkit/terraform-tools-gitops
- Gitops Bootstrap: github.com/cloud-native-toolkit/terraform-util-gitops-bootstrap
- Cert:  github.com/cloud-native-toolkit/terraform-util-sealed-secret-cert
- Cluster: github.com/cloud-native-toolkit/terraform-ocp-login
- CertManager: github.com/cloud-native-toolkit/terraform-gitops-ocp-cert-manager
- Namespace: github.com/cloud-native-toolkit/terraform-gitops-namespace


## Example usage

```hcl-terraform
module "mykafka" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-kafka-strimzi"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  cluster_name = "maskafka"
  user_name = "maskafka"
  storageclass = "ibmc-vpc-block-10iops-tier"
}
```
