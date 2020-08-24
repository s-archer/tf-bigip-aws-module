output "mgmt_cidrs" {
  value = local.mgmt_cidrs
} 

output "pub_cidrs" {
  value = local.pub_cidrs
} 

output "all_pub_cidrs" {
  value = local.all_pub_cidrs
} 

output "mgmt_ips" {
  value = local.mgmt_ips
} 

output "pub_ips" {
  value = local.pub_ips
} 

output "subnet_ids" {
  value = local.subnet_ids
} 

output "mgmt_subnet_ids" {
  value = local.mgmt_subnet_ids
} 

output "pub_subnet_ids" {
  value = local.pub_subnet_ids
} 

# - OUTPUT COMMON ---------------------------------------

# -- OUTPUT CREDS ---------------------------------------

output "f5_password" {
  value = "${random_string.password.result}"
}

output "f5_username" {
  value = "${local.json_vars.user}"
}

# - OUTPUT CONSUL -----------------------------------------

# output "consul_ui" {
#   value = "http://${aws_instance.consul.public_ip}:8500"
# }

# - OUTPUT F5-1 -------------------------------------------

# -- OUTPUT F5-1 MGMT -------------------------------------

output "f5-mgmt_pub_ip" {
  value = "${aws_eip.f5-mgmt.public_ip}"
}

output "f5-1_ui" {
  value = "https://${aws_eip.f5-mgmt.public_ip}"
}

output "f5-1_ssh" {
  value = "ssh admin@${aws_eip.f5-mgmt.public_ip} -i ssh-key.pem"
}



