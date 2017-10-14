variable "webServerInstanceType" {
  description = "webServerInstanceType"
  default = "t2.micro"
}

variable "webServerAMI" {
  description = "webServerAMI"
  default = "ami-0a85946e"
}

variable "ec2Instance1Name" {
  description = "ec2Instance1Name"
  default = "WS1"
}

variable "ec2Instance2Name" {
  description = "ec2Instance2Name"
  default = "WS2"
}

variable "serviceName" {
  description = "serviceName"
  default = "adl-gallery-ws-service"
}

variable "taskDefinition" {
  description = "task definition"
  default = "deploysimpleserver"
}