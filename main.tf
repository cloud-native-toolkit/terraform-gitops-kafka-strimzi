locals {
  name          = "apache-kafka-strimzi"
  operator_name  = "apache-kafka-strimzi-operator"
  bin_dir        = module.setup_clis.bin_dir
  tmp_dir        = "${path.cwd}/.tmp/${local.name}"
  usersecret_dir = "${local.tmp_dir}/usersecrets"
  yaml_dir       = "${local.tmp_dir}/chart/${local.name}"
  operator_yaml_dir = "${local.tmp_dir}/chart/${local.operator_name}"

  layer              = "services"
  type               = "instances"
  operator_type      = "operators"
  application_branch = "main"
  user_password      = var.user_password != null && var.user_password != "" ? var.user_password : random_password.user_password.result
  namespace          = var.namespace
  appname            = var.appname
  layer_config       = var.gitops_config[local.layer]
  installPlan        = var.installPlan

# set values content for subscription
  values_content = {
        kafka = {
          name = var.cluster_name
          username = var.user_name
          namespace = local.namespace
          size = var.kafka_size
          storageclass = var.storageclass
        }
    }
  values_content_operator = {
        subscription = {
          name = local.appname
          channel = var.channel
          installPlanApproval = local.installPlan
          source = var.catalog
          sourceNamespace = var.catalog_namespace
        }
    }
}


module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource random_password user_password {
  length           = 12
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Add values for operator chart
resource "null_resource" "deployAppValsOperator" {

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.operator_name}' '${local.operator_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content_operator)
    }
  }
}


# Add values for instance charts
resource "null_resource" "deployAppVals" {

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

# create kafka user credentials
resource null_resource create_secret {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-usersecret.sh '${var.namespace}' '${local.usersecret_dir}'"

    environment = {
      BIN_DIR = module.setup_clis.bin_dir
      KAFKA_USER = var.user_name
      KAFKA_PASS = local.user_password
    }

  }
}

module seal_secrets {
  depends_on = [null_resource.create_secret]

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git?ref=v1.1.0"

  source_dir    = local.usersecret_dir
  dest_dir      = "${local.yaml_dir}/templates"
  kubeseal_cert = var.kubeseal_cert
  label         = local.name
}



# Deploy Operator
resource gitops_module kafka_operator {
  depends_on = [null_resource.deployAppValsOperator, module.seal_secrets]

  name        = local.operator_name
  namespace   = local.namespace
  content_dir = local.operator_yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.operator_type
  branch      = local.application_branch
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

# Deploy Instance and config
resource gitops_module kafka_app {
  depends_on = [gitops_module.kafka_operator, null_resource.deployAppVals]

  name        = local.name
  namespace   = local.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.type
  branch      = local.application_branch
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
