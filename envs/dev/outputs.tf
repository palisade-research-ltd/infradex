
// --- --------------------------------------------------------------------------- NETWORKING --- //
// --- --------------------------------------------------------------------------- ---------- --- //

output "apis_enabled" {

  value       = module.networking.apis_enabled
  description = "Indicates that all APIs have been enabled"

}

// --- ------------------------------------------------------------------------------ COMPUTE --- //
// --- ------------------------------------------------------------------------------ ------- --- //

output "compute_instance_ip" {

  value = module.compute.compute_instance_ip

}

