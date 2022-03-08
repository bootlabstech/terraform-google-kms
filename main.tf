resource "google_kms_key_ring" "gcp_kms_keyring" {
  name     = "${var.kms_keyring_name}-keyring"
  location = var.location_id
  project  = var.project_id
}

resource "google_kms_crypto_key" "gcp_kms_crypto_key" {
  count           = var.prevent_destroy ? length(var.kms_key_name) : 0
  name            = var.kms_key_name[count.index]
  key_ring        = google_kms_key_ring.gcp_kms_keyring.id
  labels          = var.labels
  rotation_period = var.rotation_period
  purpose         = var.purpose
  version_template {
    algorithm        = var.algorithm
    protection_level = var.protection_level
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_key_ring_iam_binding" "kms_keyring_iam_binding" {
  for_each    = setunion(var.kms_keyring_members)
  key_ring_id = google_kms_key_ring.gcp_kms_keyring.id
  role        = "roles/cloudkms.admin"
  members     = each.value
}

resource "google_kms_crypto_key_iam_binding" "kms_key_iam_decrypter" {
  for_each      = setunion(var.kms_key_members)
  crypto_key_id = google_kms_crypto_key.gcp_kms_crypto_key[*].id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  members       = each.value
}
