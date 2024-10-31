
provider "alicloud" {
  region = "me-central-1"  // Replace with your desired region (e.g., "eu-central-1")
  access_key = ${var.access_key}
  secret_key = ${var.secret_key}
}
