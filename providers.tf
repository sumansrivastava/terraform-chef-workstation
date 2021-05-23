terraform {
  backend "gcs" {
    bucket = "pelagic-campus-310617-state-files"
    prefix = "norman/picachu"
  }
}
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.67.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}