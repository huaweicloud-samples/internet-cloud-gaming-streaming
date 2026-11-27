# ============================================================================
# 输出
# ============================================================================

output "instance_id" {
  description = "ECS 实例 ID"
  value       = huaweicloud_compute_instance.gaming.id
}

output "security_group_id" {
  description = "安全组 ID（SSH/xrdp/Sunshine 入站规则所在）"
  value       = huaweicloud_networking_secgroup.sg.id
}

output "eip_address" {
  description = "绑定的弹性公网 IP（未启用则为空字符串）"
  value       = var.assign_static_ip ? huaweicloud_vpc_eip.eip[0].address : ""
}

output "connection_hint" {
  description = "连接提示（Linux 云游戏：SSH 管理 / Moonlight 串流）"
  value = var.assign_static_ip ? (
    "SSH: ssh ubuntu@${huaweicloud_vpc_eip.eip[0].address}  (密码=admin_password)；云游戏: Moonlight 添加 ${huaweicloud_vpc_eip.eip[0].address}（Sunshine 默认端口 47984-48010）；首配 https://${huaweicloud_vpc_eip.eip[0].address}:47990"
    ) : (
    "实例在私有子网，请通过跳板机或华为云控制台「远程登录」访问"
  )
}
