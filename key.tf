
resource "alicloud_ecs_key_pair" "keyPair" {
  key_pair_name = "key-pair"
  resource_group_id = alicloud_vpc.vpc.resource_group_id

  key_file      = "keyPair.pem"
}
