
variable "ingressrules" {
  type    = list(number)
  default = [8080, 22]
}

variable "public_key" {
  type        = string
  description = "File path of public key."
  default     = "./jenkins.pub"
}

variable "private_key" {
  type        = string
  description = "File path of private key."
  default     = "./jenkins"
}

variable "domainName" {
  default = "jenkins.devopsforu.ml"
  type    = string
}
