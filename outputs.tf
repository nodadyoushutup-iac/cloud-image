output "cloud_init_yamldecoded" {
  description = "Cloud-init variable after YAML roundtrip"
  value       = yamldecode(yamlencode(var.cloud_init))
}

output "virtual_machine_yamldecoded" {
  description = "Virtual machine variable after YAML roundtrip"
  value       = yamldecode(yamlencode(var.virtual_machine))
}
