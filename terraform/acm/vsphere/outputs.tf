output acm_host_ip {
  value       = vsphere_virtual_machine.vm.default_ip_address
  description = "IP for NMS API Connectivity Manager control host"
}

output ssh_command {
  value = "ssh ${var.ssh_user}@${vsphere_virtual_machine.vm.default_ip_address}"
}

output "acm_endpoint" {
  description = "URL for NMS API Connectivity Manager control host"
  value       = "https://${vsphere_virtual_machine.vm.default_ip_address}"
}
