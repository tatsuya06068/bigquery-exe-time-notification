resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "source_bucket" {
  name     = "go-bigquery-bucket"
  location = "US"
  uniform_bucket_level_access = true
}

data "archive_file" "function_archive" {
  type        = "zip"
  source_dir  = "app"
  output_path = "app/action.zip"
}

resource "google_storage_bucket_object" "archive" {
  name   = "action.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.function_archive.output_path
}

resource "google_service_account" "default" {
  account_id   = "test-gcf-sa"
  display_name = "Test Service Account - used for both the cloud function and eventarc trigger in the test"
}



# Note: The right way of listening for Cloud Storage events is to use a Cloud Storage trigger.
# Here we use Audit Logs to monitor the bucket so path patterns can be used in the example of
# google_cloudfunctions2_function below (Audit Log events have path pattern support)
resource "google_storage_bucket" "audit_log_bucket" {
  name                        = "${random_id.bucket_prefix.hex}-gcf-auditlog-bucket"
  location                    = "us-central1" # The trigger must be in the same location as the bucket
  uniform_bucket_level_access = true
}

# Permissions on the service account used by the function and Eventarc trigger
data "google_project" "project" {
}

resource "google_project_iam_member" "invoking" {
  project = data.google_project.project.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.default.email}"
}

resource "google_project_iam_member" "event_receiving" {
  project    = data.google_project.project.project_id
  role       = "roles/eventarc.eventReceiver"
  member     = "serviceAccount:${google_service_account.default.email}"
  depends_on = [google_project_iam_member.invoking]
}

resource "google_project_iam_member" "artifactregistry_reader" {
  project    = data.google_project.project.project_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.default.email}"
  depends_on = [google_project_iam_member.event_receiving]
}

resource "google_cloudfunctions2_function" "default" {
  depends_on = [
    google_project_iam_member.event_receiving,
    google_project_iam_member.artifactregistry_reader,
  ]
  name        = "function-test"
  location    = "us-central1"
  description = "a new function"

  build_config {
    runtime     = "go121"
    entry_point = "HelloHTTP" # Set the entry point in the code
    environment_variables = {
      BUILD_CONFIG_TEST = "build_test"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.source_bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      SERVICE_CONFIG_TEST = "config_test"
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.default.email
  }

  event_trigger {
    trigger_region        = "us-central1" # The trigger must be in the same location as the bucket
    event_type            = "google.cloud.audit.log.v1.written"
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.default.email
    event_filters {
      attribute = "serviceName"
      value     = "bigquery.googleapis.com"
    }
    event_filters {
      attribute = "methodName"
      value     = "jobservice.jobcompleted"
    }

  }
}