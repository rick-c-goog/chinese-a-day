locals {
  appname = "chinese_words"
  cron_topic = "${var.project_id}-daily-words" 
  send_daily_topic = "${var.project_id}-send-daily-words" 

}

/******************************************
1. Project Services Configuration
 *****************************************/
module "activate_service_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                  = var.project_id
  enable_apis                 = true

  activate_apis = [
    "orgpolicy.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "appengine.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudbuild.googleapis.com"
  ]

  disable_services_on_destroy = false
  
}

resource "time_sleep" "sleep_after_activate_service_apis" {
  create_duration = "60s"

  depends_on = [
    module.activate_service_apis
  ]
}

/******************************************
2. Project-scoped Org Policy Relaxing
*****************************************/

module "org_policy_allow_ingress_settings" {
source = "terraform-google-modules/org-policy/google"
policy_for = "project"
project_id = var.project_id
constraint = "constraints/cloudfunctions.allowedIngressSettings"
policy_type = "list"
enforce = false
allow= ["IngressSettings.ALLOW_ALL"]
depends_on = [
time_sleep.sleep_after_activate_service_apis
]
}

module "org_policy_allow_domain_membership" {
source = "terraform-google-modules/org-policy/google"
policy_for = "project"
project_id = var.project_id
constraint = "constraints/iam.allowedPolicyMemberDomains"
policy_type = "list"
enforce = false
depends_on = [
time_sleep.sleep_after_activate_service_apis
]
}

/******************************************
3. Create a pubsub topic
 *****************************************/
resource "google_pubsub_topic" "daily_words" {
  name = local.cron_topic

  labels = {
    job = "daily-words-job"
  }

  message_retention_duration = "86600s"
}


resource "google_pubsub_topic" "send_daily_words" {
  name = local.send_daily_topic

  labels = {
    job = "send-daily-words"
  }

  message_retention_duration = "86600s"
}


/******************************************
4.Create a cloud scheduler
 *****************************************/
resource "google_cloud_scheduler_job" "daily_words_schedule" {
  name        = "daily_words_schedule"
  description = "set daily words job "
  schedule    = "0 20 * * *"
  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.daily_words.id
    data       = base64encode("test")
  }
}

/******************************************
5. Create set daily words cloud functions
 *****************************************/
resource "google_storage_bucket" "function_bucket" {
    name     = "${local.appname}-function"
    location = var.region
    uniform_bucket_level_access       = true
    force_destroy                     = true
}
#clean up the main.py variables
resource "null_resource" "clean_up_set_daily_words" {
  provisioner "local-exec" {
    command = <<-EOT
    cp -R -r -f ../src/shared ../src/set_todays_words 
   EOT
  }

}

data "archive_file" "set_daily_words_archive" {
    type        = "zip"
    source_dir  = "../src/set_todays_words"
    output_path = "tmp/set_todays_words.zip"
    depends_on   = [ 
        null_resource.clean_up_set_daily_words
    ]
}

# Add source code zip to the Cloud Function's bucket
resource "google_storage_bucket_object" "set_daily_words_zip" {
    source       = data.archive_file.set_daily_words_archive.output_path
    content_type = "application/zip"

    # Append to the MD5 checksum of the files's content
    # to force the zip to be updated as soon as a change occurs
    name         = "src-${data.archive_file.set_daily_words_archive.output_md5}.zip"
    bucket       = google_storage_bucket.function_bucket.name

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on   = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        data.archive_file.set_daily_words_archive
    ]
}



# Create the Cloud function triggered by a `Finalize` event on the bucket
resource "google_cloudfunctions_function" "set_daily_words_function" {
    name                  = "set_daily_words_function"
    runtime               = "python39"  # of course changeable

    # Get the source code of the cloud function as a Zip compression
    source_archive_bucket = google_storage_bucket.function_bucket.name
    source_archive_object = google_storage_bucket_object.set_daily_words_zip.name

    # Must match the function name in the cloud function `main.py` source code
    entry_point           = "function_handler"
    
    # 
    event_trigger {
      event_type= "google.pubsub.topic.publish"
      resource= "${local.cron_topic}"
      #service= "pubsub.googleapis.com"
    }
    environment_variables = {
    PROJECT_ID = var.project_id
    }

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on            = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        google_storage_bucket_object.set_daily_words_zip
    ]
}

#Fire Store database creation 
resource "google_app_engine_application" "app" {
  count=0
  project     = var.project_id
  location_id = var.region
  database_type = "CLOUD_FIRESTORE"
}


#clean up the main.py variables
resource "null_resource" "load_data" {
  provisioner "local-exec" {
    command = <<-EOT
    cd ../src/load_data
    pip install -r requirements.txt
    python main.py
   EOT
  }

}
