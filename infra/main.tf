# ============================================================================
# 华为云 · Linux GPU 云游戏实例
# ============================================================================
# 资源映射：
#   huaweicloud_compute_instance        ECS 实例（Ubuntu + GRID 公共镜像）
#   huaweicloud_networking_secgroup     安全组 + 规则
#   huaweicloud_vpc_eip                 弹性公网 IP
#   huaweicloud_vpc_eip_associate       EIP 绑定到 ECS
#   IAM Role/Profile    ：无需（ECS 密码登录即可访问控制台）
#   LaunchTemplate      ：无需（华为云无对应资源，MetadataOptions 由镜像默认满足）
#   user_data.sh(cloud-init bash)：安装 Steam + Sunshine 提供云游戏接入
# 关键适配：cn-north-4 无公共 Windows 镜像，本实践使用官方 GRID 公共镜像（Linux + GPU）；GPU 驱动由镜像预装。
# ============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
  }

  backend "local" {}
}

# ----------------------------------------------------------------------------
# Provider 配置：凭据从环境变量读取，不写入代码或文件
#   export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
#   export HW_SECRET_KEY="<HW_SECRET_KEY>"
# ----------------------------------------------------------------------------
provider "huaweicloud" {
  region = var.region
}

# ----------------------------------------------------------------------------
# 安全组：入站放行 SSH(22) / xrdp(3389) / Sunshine+Moonlight(47984-48010)
# 出方向华为云默认 allow-all egress，无需显式建（docs/13 §3，显式建会 conflict）
# ----------------------------------------------------------------------------
resource "huaweicloud_networking_secgroup" "sg" {
  name        = "${var.instance_name}-sg"
  description = "Inbound for Linux cloud-gaming: SSH(22) / xrdp(3389) / Sunshine+Moonlight(47984-48010)"
}

locals {
  # 入站规则表：proto + 端口区间
  ingress_rules = [
    { proto = "tcp", min = 22,    max = 22    }, # SSH 管理
    { proto = "tcp", min = 3389,  max = 3389  }, # xrdp 桌面（备选接入）
    { proto = "tcp", min = 47984, max = 48010 }, # Sunshine / Moonlight（TCP）
    { proto = "udp", min = 47998, max = 48000 }, # Moonlight（UDP 串流）
  ]
}

resource "huaweicloud_networking_secgroup_rule" "ingress" {
  for_each          = { for i, r in local.ingress_rules : i => r }
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.proto
  port_range_min    = each.value.min
  port_range_max    = each.value.max
  remote_ip_prefix  = var.ingress_cidr
  security_group_id = huaweicloud_networking_secgroup.sg.id
}

# ----------------------------------------------------------------------------
# ECS Linux GPU 实例（Ubuntu + GRID 公共镜像）
# user_data 为 cloud-init 执行的 bash 引导脚本（见 user_data.sh）
# ----------------------------------------------------------------------------
resource "huaweicloud_compute_instance" "gaming" {
  name              = var.instance_name
  image_id          = var.image_id
  flavor_id         = var.flavor_id
  availability_zone = var.availability_zone != "" ? var.availability_zone : null

  security_group_ids = [huaweicloud_networking_secgroup.sg.id]
  admin_pass         = var.admin_password

  # cloud-init 在首启动解码并执行该 bash 脚本（安装桌面 / Steam / Sunshine）
  user_data = base64encode(file("${path.module}/user_data.sh"))

  network {
    uuid = var.subnet_id
  }

  # 系统盘：类型与容量由变量显式指定；system_disk_type 为华为云必填项
  system_disk_type = var.system_disk_type
  system_disk_size = var.volume_size

  tags = {
    Source     = "huaweicloud-practice"
    UseCase    = "cloud-gaming-linux"
    GitHubFork = "开源样例/internet-cloud-gaming-streaming"
  }
}

# ----------------------------------------------------------------------------
# 弹性公网 IP（可选）：需要固定公网入口时创建
# 用量型带宽（charge_mode=traffic）
# ----------------------------------------------------------------------------
resource "huaweicloud_vpc_eip" "eip" {
  count = var.assign_static_ip ? 1 : 0

  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "${var.instance_name}-bw"
    size        = var.eip_bandwidth_size
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_vpc_eip_associate" "eip_assoc" {
  count       = var.assign_static_ip ? 1 : 0
  public_ip   = huaweicloud_vpc_eip.eip[0].address
  port_id     = huaweicloud_compute_instance.gaming.network[0].port
}
