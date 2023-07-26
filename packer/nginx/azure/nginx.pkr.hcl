/**
 * Copyright (c) F5, Inc.
 *
 * This source code is licensed under the Apache License, Version 2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}

variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}

variable "client_secret" {
  type      = string
  default   = "${env("ARM_CLIENT_SECRET")}"
  sensitive = true
}

variable "base_image_offer" {
  type    = string
}

variable "base_image_sku" {
  type    = string
}

variable "base_image_publisher" {
  type    = string
}

variable "resource_group_name" {
  type    = string
  default = "West Central US"
}

variable "build_instance_type" {
  type    = string
  default = "Standard_B1s"
}

variable "image_name"{
  type    = string
  default = null
}

variable "nginx_repo_cert" {
  type = string
}

variable "nginx_repo_key" {
  type = string
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

locals {
  timestamp = formatdate("YYYY-MM-DD", timestamp())
  image_name = var.image_name != null ? var.image_name : "nginx-${local.timestamp}"
}

source "azure-arm" "disk" {
  build_resource_group_name         = var.resource_group_name
  image_offer                       = var.base_image_offer
  image_publisher                   = var.base_image_publisher
  image_sku                         = var.base_image_sku
  managed_image_name                = local.image_name
  managed_image_resource_group_name = var.resource_group_name
  os_type                           = "Linux"
  ssh_clear_authorized_keys         = true
  ssh_username                      = var.ssh_username
  vm_size                           = var.build_instance_type
  subscription_id                   = var.subscription_id
  client_id                         = var.client_id
  client_secret                     = var.client_secret
}



build {
  sources = ["source.azure-arm.disk"]

  provisioner "shell" {
    inline = ["cloud-init status --wait"]
  }

  provisioner "shell" {
    scripts = ["${path.root}/../../scripts/img-prep.sh"]
  }

  provisioner "shell-local" {
    inline = ["${path.root}/../../scripts/write_agent_ansible_group_vars.sh ${var.nginx_repo_cert} ${var.nginx_repo_key}"]
  }

  provisioner "ansible" {
    ansible_env_vars = ["ANSIBLE_SSH_ARGS=-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=ssh-rsa", "ANSIBLE_HOST_KEY_CHECKING=False", "ANSIBLE_CONFIG=../../ansible/ansible.cfg"]
    extra_arguments  = ["-e ansible_ssh_pass=${var.ssh_username}"]
    groups           = ["agent"]
    playbook_file    = "../../ansible/play-agent.yml"
  }

  provisioner "shell" {
    scripts = ["${path.root}/../../scripts/required-setup-all.sh"]
  }

  post-processor "manifest" {
  }
}
