# 真实变量文件（勿提交含密码的版本；AK/SK 不写此文件，由环境变量注入）
# 认证信息通过环境变量提供（apply 前设置）：
#   export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
#   export HW_SECRET_KEY="<HW_SECRET_KEY>"
#   export HW_REGION_NAME="cn-north-4"

region               = "cn-north-4"
image_id             = "72b9893f-4990-4f22-a9c3-79311555ecad"   # 公共(官方)镜像：Ubuntu 20.04 server 64bit with GRID Driver 11.1（预装 NVIDIA GRID 图形驱动，云游戏免手动装驱动；visibility=public，无需市场订阅）
flavor_id            = "g6v.2xlarge.4"                             # 图形加速型 T4，8vCPU/32GB，支持 Linux
instance_name        = "Ubuntu-GPU-GAMING"
availability_zone    = ""                                        # 留空由平台分配
subnet_id            = "06b8fe12-696c-4734-8321-889f584db874"     # 查询所得（账号内唯一子网）
assign_static_ip     = true                                       # 方案 A：开 EIP，不使用 NAT
ingress_cidr         = "0.0.0.0/0"                                  # 全网放行（临时验证用，用完 terraform destroy）
# admin_password 不写在此文件，由 apply 时通过 TF_VAR_admin_password 环境变量注入（避免落盘）
system_disk_type     = "GPSSD"
volume_size          = 550
eip_bandwidth_size   = 5
