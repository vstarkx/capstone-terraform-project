resource "alicloud_security_group" "http-sg" {
  name        = "http"
  description = "http security group"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "ssh_for_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.http-sg.id
  source_security_group_id = alicloud_security_group.bastion.id
}
resource "alicloud_security_group_rule" "allow_ssh_to_http" {
  type                     = "ingress"
  ip_protocol              = "tcp"
  policy                   = "accept"
  port_range               = "22/22"
  priority                 = 1
  security_group_id        = alicloud_security_group.http-sg.id
  cidr_ip           = "0.0.0.0/0"
}
