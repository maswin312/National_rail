// Airbyte Terraform provider documentation: https://registry.terraform.io/providers/airbytehq/airbyte/latest/docs

// Sources
resource "airbyte_source_google_sheets" "googlesheets" {
  configuration = {
    batch_size = 8
    credentials = {
      service_account_key_authentication = {
        service_account_info = file(var.credentials_json_path)
      }
    }
    names_conversion = false
    spreadsheet_id   = var.spreadsheet_id
  }
  name          = "Sheets Maven Train TF"
  workspace_id  = var.workspace_id
}

// Destinations
resource "airbyte_destination_bigquery" "bigquery" {
  configuration = {
    dataset_id       = var.dataset_id
    dataset_location = "asia-southeast2"
    destination_type = "bigquery"
    project_id       = var.project_id
    credentials_json = file(var.credentials_json_path)
    loading_method = {
      gcs_staging = {
        credential = {
          hmac_key = {
            hmac_key_access_id = var.hmac_key_access_id
            hmac_key_secret    = var.hmac_key_secret
          }
        }
        gcs_bucket_name          = var.gcs_bucket_name
        gcs_bucket_path          = var.gcs_bucket_path
        keep_files_in_gcs_bucket = "Delete all tmp files from GCS"
      }
      
    }
  }
  name         = "BQ maven train TF"
  workspace_id = var.workspace_id
}

// Connections
resource "airbyte_connection" "National_Rail_Data" {
  name           = "National Rail Sheets to BigQuery"
  source_id      = airbyte_source_google_sheets.googlesheets.source_id
  destination_id = airbyte_destination_bigquery.bigquery.destination_id
  configurations = {
    streams = [
      {
        name = "railway"
      },
     
    ]
  }
}
