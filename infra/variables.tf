# ============================================================================
# 变量定义
# ============================================================================
# 说明：镜像 / 规格 / 网络均显式由用户提供，不借助 data 源下拉，
# 以保证 `terraform plan` 可离线执行、资源规格可被精确预览。

variable "region" {
  description = "华为云区域，例如 cn-north-4（北京四）"
  type        = string
  default     = "cn-north-4"
}

variable "image_id" {
  description = "公共(官方) Linux GPU 镜像 ID。cn-north-4 无公共 Windows 镜像（仅市场镜像），故改用官方 GRID 公共镜像，例如「Ubuntu 20.04 server 64bit with GRID Driver 11.1」(id 72b9893f-4990-4f22-a9c3-79311555ecad) 或「Ubuntu 22.04 server 64bit with Graphic driver 580.126.09」。GRID 镜像预装 NVIDIA 图形驱动，云游戏免手动装驱动。随 region 变化，必须显式提供。"
  type        = string
}

variable "flavor_id" {
  description = "ECS 规格（GPU 图形加速型）。选用华为云图形加速型 G6v（NVIDIA T4，原生支持图形/渲染/云游戏），如 g6v.2xlarge.4（8vCPU/32G/1*T4）。注意 flavor 命名带内存倍数后缀(.4)；Linux 公共镜像可与 G6/G6v 任意 GPU flavor 组合。"
  type        = string
  default     = "g6v.2xlarge.4"
}

variable "instance_name" {
  description = "ECS 实例名称"
  type        = string
  default     = "Ubuntu-GPU-GAMING"
}

variable "availability_zone" {
  description = "可用区，例如 cn-north-4a。留空由平台分配。"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "目标子网 ID（须与实例同 AZ；实例经 EIP 直连公网，子网无需额外 NAT/IGW）"
  type        = string
}

variable "assign_static_ip" {
  description = "是否绑定弹性公网 IP（EIP）。默认 true=分配静态公网 IPv4 并绑定到实例，作为唯一公网出口（不使用 NAT 网关）。设为 false 时实例将无公网 IP，必须自行在 VPC 内配置 NAT 网关/IGW 才能出网与 RDP 接入。"
  type        = bool
  default     = true
}

variable "ingress_cidr" {
  description = "允许入站(SSH 22 / xrdp 3389 / Sunshine+Moonlight 47984-48010 UDP/TCP)的源 IPv4 前缀，强烈建议限定为你的出口 IP/32，例如 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/32"
}

variable "admin_password" {
  description = "Linux root 密码（同时作为 ubuntu 用户密码），SSH/xrdp 登录用。长度 8-26，含大小写+数字+特殊字符中至少三类。敏感，勿提交。"
  type        = string
  sensitive   = true
}

variable "system_disk_type" {
  description = "系统盘类型：GPSSD（通用型 SSD，推荐）/ SSD / SAS。"
  type        = string
  default     = "GPSSD"
}

variable "volume_size" {
  description = "系统盘容量(GiB)，默认 550GiB"
  type        = number
  default     = 550
}

variable "eip_bandwidth_size" {
  description = "EIP 带宽大小(Mbps)，仅 assign_static_ip=true 时生效。charge_mode=traffic（用量型，空闲≈0）"
  type        = number
  default     = 5
}
