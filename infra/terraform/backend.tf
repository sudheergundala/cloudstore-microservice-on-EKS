terraform {
  backend "s3" {
    bucket       = "cloudstore-tfstate-317471961465"
    key          = "cloudstore/dev/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
    region       = "us-east-1"
  }
}