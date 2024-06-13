variable "gcp_key" {
  description = "My json key credentials"
  default     = "zoomcamp_key.json"
}

variable "project" {
  description = "My project"
  default     = "belajar-data-maswin"
}


variable "location" {
  description = "My project location"
  default     = "asia-southeast2"
}

variable "region" {
  description = "My project region"
  default     = "asia-southeast2"
}


variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "maven_train_data"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "maven-train-data-source"
}


variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}