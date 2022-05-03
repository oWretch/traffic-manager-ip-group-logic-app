variable "ip_group_name" {
  type        = string
  description = "Resource Name for the IP Group."
}

variable "logic_app_name" {
  type        = string
  description = "Resource Name for the Logic App."
}

variable "resource_group_name" {
  type        = string
  description = "Name for the Resource Group."
}

variable "location" {
  type        = string
  description = "Location where the resources should be deployed."
}

variable "time_zone" {
  type        = string
  description = "Timezone used for calculating the scheduled run time."
  default     = "UTC"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
}
