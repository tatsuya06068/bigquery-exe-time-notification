resource "google_project_iam_audit_config" "audit-config" {
    // project id
    project = "bigquery-example-403506"

    # 有効化したいサービスを列挙する
    for_each = toset([
    "bigquerydatapolicy.googleapis.com",
    ])

    service = each.value


    # 有効化したい監査ログの種別を列挙する
    audit_log_config {
    log_type = "ADMIN_READ"
    }
    audit_log_config {
    log_type = "DATA_READ"
    }
    audit_log_config {
    log_type = "DATA_WRITE"
    }
}