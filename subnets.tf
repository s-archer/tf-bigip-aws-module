# This file automatically generates subnets and IPs based on the values provided in the variables.json file.  Specifically:
#
# "public_subnets": {
#     "ip_count": 200,
#     "ip_start": 11,
#     "ip_count_per_subnet": 20
#
#  I will work on getting the following working later:
# "private_subnets": {
#     "private_ip_count": 2
# 

# Get the VPC CIDR.
locals {
  cidr = local.json_vars.cidr
}

# Auto generate the public MGMT subnet from the CIDR.
locals {
  mgmt_cidrs = [cidrsubnet(local.cidr, 8, 0)]
}

# Determine how many public 'tmm' subnets are required. For example, you might set the max_ip_count_per_subnet to 20, because that is
# the maximum number of IPs an EC2 instance can support on a single interface.  Therefore if you need 25 public IPs, we would need two
# public subnets, the first could accommodate 20 IPs and the second could accommodate the remaining 5 IPs.
locals {
  pub_cidr_qty = min((local.json_vars.public_subnets.total_ip_count / local.json_vars.public_subnets.max_ip_count_per_subnet), 20)
}

# Auto generate a list containing the correct quantity of public 'tmm' subnets.   
locals {
  pub_cidrs = [
      for i in range(local.pub_cidr_qty) : cidrsubnet(local.cidr, 8, (i + 1))
  ]
}

# Auto generate a list of all public ('mgmt' and 'tmm') subnets.
locals {
  all_pub_cidrs = [
      for i in range(local.pub_cidr_qty + 1) : cidrsubnet(local.cidr, 8, (i))
  ]
}

# Auto generate the mgmt IP (.5) using the mgmt subnet.
locals {
  mgmt_ips = {
      for each_cidr in local.mgmt_cidrs :
        each_cidr => [ for i in range(1) : 
          cidrhost(each_cidr, (i + 5))
        ]
  }
}

# Auto generate the correct quantity of public 'tmm' IPs, using as many subnets as necessary. Creates a map of subnets, each containing a list of IPs.
locals {
  pub_ips = {
    for each_chunk in chunklist(range(1, (local.json_vars.public_subnets.total_ip_count+1)), local.json_vars.public_subnets.max_ip_count_per_subnet) :
      cidrsubnet(local.cidr, 8,(((each_chunk[0] + (local.json_vars.public_subnets.max_ip_count_per_subnet - 1)) / local.json_vars.public_subnets.max_ip_count_per_subnet))) => [ for i in range(length(each_chunk)) : 
          cidrhost(cidrsubnet(local.cidr, 8,(((each_chunk[0] + (local.json_vars.public_subnets.max_ip_count_per_subnet - 1)) / local.json_vars.public_subnets.max_ip_count_per_subnet))), (i + 9))
      ]
      }
}

# Now create simple list of just the 'tmm' IPs.  Need this list to loop through, in order to attach EIPs to each of them.
locals {
  pub_ips_list = flatten([
    for each_subnet in local.pub_ips :
      each_subnet
  ])
}

# After the subnets are created, we can get ALL the subnet IDs
locals {
  subnet_ids = module.vpc.public_subnets[*]
}

# After the subnets are created, we can get the mgmt subnet IDs
locals {
  mgmt_subnet_ids = module.vpc.public_subnets[0]
}

# After the subnets are created, we can get the tmm subnet IDs
locals {
  pub_subnet_ids = slice(module.vpc.public_subnets, 1, length(module.vpc.public_subnets))
}
