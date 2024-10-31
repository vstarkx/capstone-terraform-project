resource "alicloud_vpc" "vpc" {
  vpc_name   = "capstone-vpc"
  cidr_block = "10.0.0.0/8"
}
data "alicloud_zones" "availability_zones" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_nat_gateway" "default" {
  vpc_id           = alicloud_vpc.vpc.id
  nat_gateway_name = "http"
  payment_type     = "PayAsYouGo"
  vswitch_id       = alicloud_vswitch.vswitch_public_a.id
  nat_type         = "Enhanced"
}

resource "alicloud_eip_address" "nat" {
  description            = "nat"
  address_name           = "nat"
  netmode                = "public"
  bandwidth              = "100"
  payment_type           = "PayAsYouGo"
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip_association" "nat" {
  allocation_id = alicloud_eip_address.nat.id
  instance_id   = alicloud_nat_gateway.default.id
  instance_type = "Nat"
}

resource "alicloud_snat_entry" "http_private" {
  snat_table_id     = alicloud_nat_gateway.default.snat_table_ids
  source_vswitch_id = alicloud_vswitch.vswitch_private.id
  snat_ip           = alicloud_eip_address.nat.ip_address
}

resource "alicloud_route_table" "private" {
  description      = "Private"
  vpc_id          = alicloud_vpc.vpc.id
  route_table_name = "private"
  associate_type  = "VSwitch"
}

resource "alicloud_route_entry" "nat" {
  route_table_id         = alicloud_route_table.private.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type           = "NatGateway"
  nexthop_id             = alicloud_nat_gateway.default.id
}

resource "alicloud_route_table_attachment" "private" {
  vswitch_id    = alicloud_vswitch.vswitch_private.id
  route_table_id = alicloud_route_table.private.id
}



variable "app_name" {
  default = "my_app"
}


resource "alicloud_nlb_load_balancer" "default" {
  load_balancer_type = "Network"
  load_balancer_name = "http-load-balancer"
  
  address_type       = "Internet"
  address_ip_version = "Ipv4"
  vpc_id             = alicloud_vpc.vpc.id
  zone_mappings {
    vswitch_id = alicloud_vswitch.vswitch_public_a.id
    zone_id    = data.alicloud_zones.availability_zones.zones.0.id
  }
  zone_mappings {
    vswitch_id = alicloud_vswitch.vswitch_public_b.id
    zone_id    = data.alicloud_zones.availability_zones.zones.1.id
  }
}

resource "alicloud_nlb_server_group" "default" {
  server_group_name        = "http-server-group"
  server_group_type        = "Instance"
  vpc_id                   = alicloud_vpc.vpc.id
  scheduler                = "Rr"
  protocol                 = "TCP"
  connection_drain_timeout = 60
  address_ip_version       = "Ipv4"
  health_check {
    health_check_enabled         = true
    health_check_type            = "TCP"
    health_check_connect_port    = 0
    healthy_threshold            = 2
    unhealthy_threshold          = 2
    health_check_connect_timeout = 5
    health_check_interval        = 10
    http_check_method            = "GET"
    health_check_http_code       = ["http_2xx", "http_3xx", "http_4xx"]
  }
}

resource "alicloud_nlb_server_group_server_attachment" "default" {
    count = length(alicloud_instance.http_web)
  server_type     = "Ecs"
  server_id       = alicloud_instance.http_web[count.index].id
  port            = 80
  server_group_id = alicloud_nlb_server_group.default.id
  weight          = 100
}
resource "alicloud_nlb_listener" "default" {
  listener_protocol      = "TCP"
  listener_port          = "80"
  listener_description   = "http-listener"
  load_balancer_id       = alicloud_nlb_load_balancer.default.id
  server_group_id        = alicloud_nlb_server_group.default.id
  idle_timeout           = "900"
  cps                    = "0"
  mss                    = "0"
}

output "dns_name" {
    value = alicloud_nlb_load_balancer.default.dns_name
  
}



resource "alicloud_vswitch" "vswitch_public_a" {
  vswitch_name      = "vswitch_public_a" 
  cidr_block        = "10.0.1.0/24" 
  vpc_id            = "${alicloud_vpc.vpc.id}" 
  zone_id = "${data.alicloud_zones.availability_zones.zones.0.id}"
}


resource "alicloud_vswitch" "vswitch_public_b" {
  vswitch_name      = "vswitch_public_b"
  cidr_block        = "10.0.2.0/24"
  vpc_id            = "${alicloud_vpc.vpc.id}"
  zone_id = "${data.alicloud_zones.availability_zones.zones.1.id}" 
}


resource "alicloud_vswitch" "vswitch_private" {
  vswitch_name      = "vswitch_private"
  cidr_block        = "10.0.3.0/24"
  vpc_id            = "${alicloud_vpc.vpc.id}"
  zone_id = "${data.alicloud_zones.availability_zones.zones.0.id}" 
}
