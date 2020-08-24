
resource "random_string" "password" {
  length  = 10
  special = false
}

data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = [local.json_vars.f5_ami_search_name]
  }
}

# MGMT INTERFACE ---------------
resource "aws_network_interface" "f5-mgmt" {
  subnet_id       = local.mgmt_subnet_ids
  security_groups = [aws_security_group.f5.id]
  private_ips     = local.mgmt_ips[local.mgmt_cidrs[0]]

  tags = {
    Name = "${local.json_vars.prefix}-mgmt_interface"
  }
}

resource "aws_eip" "f5-mgmt" {
  network_interface = aws_network_interface.f5-mgmt.id
  associate_with_private_ip = local.mgmt_ips[local.mgmt_cidrs[0]][0]
  vpc               = true

  tags                      = {
    Name                    = "${local.json_vars.prefix}-mgmt"
  }
}

# # EXT INTERFACE ----------------

resource "aws_network_interface" "f5-ext" {
  count           = length(local.pub_subnet_ids)
  subnet_id       = local.pub_subnet_ids[count.index]
  security_groups = [aws_security_group.f5.id]
  private_ips     = local.pub_ips[local.pub_cidrs[count.index]]

  tags = {
    Name = "${local.json_vars.prefix}-external_interface"
  }
}

resource "aws_eip" "f5-ext" {
  count                     = local.json_vars.public_subnets.total_ip_count 
  network_interface         = aws_network_interface.f5-ext[(floor(count.index / local.json_vars.public_subnets.max_ip_count_per_subnet))].id
  associate_with_private_ip = local.pub_ips_list[count.index]
  vpc                       = true

  tags                      = {
    Name                    = "${local.json_vars.prefix}-1-ext-self"
  }
}


# # INT INTERFACE ----------------

# resource "aws_network_interface" "f5-1_eth1_2_int" {
#   subnet_id   = module.vpc.private_subnets[0]
#   security_groups = [aws_security_group.f5_internal.id]
#   private_ips = ["10.0.2.101"]

#   tags = {
#     Name = "internal_interface"
#   }
# }

# # ONBOARDING TEMPLATE  ---------

data "template_file" "f5-1_init" {
  template = file("../scripts/f5_onboard.tmpl")

  vars = {
    password              = random_string.password.result
    doVersion             = "latest"
    #example version:
    #as3Version           = "3.16.0"
    as3Version            = "latest"
    tsVersion             = "latest"
    cfVersion             = "latest"
    fastVersion           = "latest"
    libs_dir              = local.json_vars.libs_dir
    onboard_log           = local.json_vars.onboard_log
    projectPrefix         = local.json_vars.prefix
  }
}

# # AMI INSTANCE ----------------

resource "aws_instance" "f5-1" {

  ami = data.aws_ami.f5_ami.id

  instance_type               = "m5.xlarge"
  user_data                   = data.template_file.f5-1_init.rendered
  key_name                    = aws_key_pair.demo.key_name

  root_block_device { delete_on_termination = true }

  network_interface {
    network_interface_id = aws_network_interface.f5-mgmt.id
    device_index         = 0
  }

  dynamic "network_interface" {
    for_each = aws_network_interface.f5-ext
    content {
      network_interface_id = network_interface.value.id
      device_index         = (network_interface.key + 1)
    }
  }

  provisioner "local-exec" {
    command = "while [[ \"$(curl -skiu ${local.json_vars.user}:${random_string.password.result} https://${self.public_ip}/mgmt/shared/appsvcs/declare | grep -Eoh \"^HTTP/1.1 204\")\" != \"HTTP/1.1 204\" ]]; do sleep 5; done"
  }
  
  tags = {
    Name  = "${local.json_vars.prefix}-f5-1"
    UK-SE = local.json_vars.tags.uk-se
  }
}


