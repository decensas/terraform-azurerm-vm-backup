terraform {
  required_version = ">= 1.3.0" # Also update terraform version in .github/workflows/pre-commit.yml

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}
