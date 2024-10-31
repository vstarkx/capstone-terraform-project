resource "alicloud_security_group" "mysql-sg" {
  name        = "mysql-sg"
  vpc_id = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_bastion_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.mysql-sg.id
  source_security_group_id = alicloud_security_group.bastion.id
}

resource "alicloud_security_group_rule" "allow_http_mysql" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "3306/3306"
  priority          = 1
  security_group_id = alicloud_security_group.mysql-sg.id
  source_security_group_id = alicloud_security_group.http-sg.id
}
