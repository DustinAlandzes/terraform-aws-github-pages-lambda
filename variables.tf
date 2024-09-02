variable "github_repository_name" {
  type        = string
  description = "Name of the Github repository that will be created."
}

variable "github_repository_privacy" {
  type        = string
  description = "Name of the Github repository that will be created."
  default     = "public"

  validation {
    condition     = var.github_repository_privacy == "public" || var.github_repository_privacy == "private"
    error_message = "The Github repository's privacy must be 'public' or 'private'"
  }
}

variable "email" {
  type        = string
  description = "Email to send form input to."
}