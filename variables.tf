
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
  sensitive   = true
}

variable "namespace" {
  type        = string
  description = "The namespace where the application should be deployed"
}

variable "kubeseal_cert" {
  type        = string
  description = "The certificate/public key used to encrypt the sealed secrets"
  default     = ""
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "channel" {
  type        = string
  description = "Subscription channel"
  default     = "strimzi-0.22.x"
}

variable "installPlan" {
  type        = string
  description = "Install Plan for App"
  default     = "Automatic"
}

variable "catalog" {
  type        = string
  description = "App catalog source"
  default     = "community-operators"
}

variable "catalog_namespace" {
  type        = string
  description = "Catalog source namespace"
  default     = "openshift-marketplace"
}

variable "appname" {
  type        = string
  description = "Name of kafka to install"
  default     = "strimzi-kafka-operator"
}

variable "cluster_name" {
  type        = string
  description = "Name of kafka cluster"
  default     = "mykafka"
}

variable "user_name" {
  type        = string
  description = "Name of kafka user"
  default     = "kfuser"
}

variable "user_password" {
  type        = string
  sensitive   = true
  description = "password for the kafkauser, if not defined it will generate a random password"
  default     = ""
}

variable "kafka_size" {
  type        = string
  description = "The kafka cluster size to create: small or large"
  default     = "small"
}

variable "storageclass" {
  type        = string
  description = "block storage to use for deployment"
  default     = ""
}
