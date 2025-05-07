
output "apis_enabled" {

  value = google_project_service.enable_apis
  description = "Indicates that all APIs have been enabled"

}

