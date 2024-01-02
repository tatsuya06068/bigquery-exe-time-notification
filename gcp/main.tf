#terraform setting
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google" # terraformレジストリからインストール
      version = "5.10.0"           # terraformのバージョン
    }
  }
}

provider "google" {
  credentials = file("./credential/bigquery-example-403506-2ba487cc14c8.json")
  project = "bigquery-example-403506"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}
