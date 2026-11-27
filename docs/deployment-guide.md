# 部署指导书 · Linux GPU 云游戏实例（Steam + Sunshine）

## 前置条件

- 华为云账号，具备 ECS / VPC / EIP 创建权限。
- 已安装 Terraform >= 1.5（本实践在 1.9.x 验证）。
- 目标 Region 已存在可用 VPC 与子网，且子网具备公网出口（绑定 EIP 或经 NAT）。
- 准备以下信息：
- **公共(官方) Linux GPU 镜像 ID**：控制台「镜像服务 → 公共镜像」选取带 GRID/Graphic 驱动的，例如 `Ubuntu 20.04 server 64bit with GRID Driver 11.1`（id `72b9893f-4990-4f22-a9c3-79311555ecad`），或 `Ubuntu 22.04 with Graphic driver 580`。**不要选 Windows 镜像**（cn-north-4 无公共 Windows 镜像，市场镜像需订阅）；
- 目标 `subnet_id`（无需 `vpc_id`）；
- 一个符合复杂度要求的 root 密码（8–26 位，大小写+数字+特殊字符中至少三类）。

## 凭据（安全红线）

- **绝不**将 AK/SK 写入 `.tf` / `tfvars` 文件。改用环境变量：

```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
export HW_SECRET_KEY="<HW_SECRET_KEY>"
export HW_REGION_NAME="cn-north-4" # 与变量 region 一致
```

> ⚠️ 若你此前在别处明文粘贴过 AK/SK，请立即到华为云控制台「我的凭证 → 访问密钥」禁用并重新生成。

## 快速开始

```bash
cd infra
terraform init
terraform plan \
-var="image_id=72b9893f-4990-4f22-a9c3-79311555ecad" \
-var="subnet_id=<subnet-xxxx>" \
-var='admin_password=<你的强密码>' \
-var="ingress_cidr=1.2.3.4/32" \
-var="assign_static_ip=true"

# 确认 plan 无误、且费用已确认（见下文「费用」）后，再执行：
terraform apply # 同上 -var 参数（admin_password 也可走 TF_VAR_admin_password 环境变量）
```

> 本项目已附带 `.tfvars`（含 image_id / subnet_id / ingress_cidr / flavor_id），只需补 `admin_password`（建议走 `TF_VAR_admin_password` 环境变量，避免落盘）。

## 分步部署

1. `terraform init` —— 拉取 huaweicloud Provider。
2. `terraform plan` —— 预览将创建的资源（安全组 4 条入站规则 + ECS + EIP 绑定）。
3. 确认费用（见下）并获得许可后 `terraform apply`。
4. 等待实例就绪（首启动 `user_data.sh` 安装桌面 / Steam / Sunshine，约 5–15 分钟）。
5. 用 Moonlight 连接 EIP 串流；或用 SSH / xrdp 接入管理。

## GPU 图形驱动

- **已解决**：所选公共 GRID 镜像**出厂预装 NVIDIA GRID 图形驱动**，无需手动安装，且支持无显示器虚拟显示（Sunshine 串流所需）。
- 若改用不带驱动的镜像（如 `Ubuntu 22.04 with NO Driver`），需部署后通过控制台「切换 GPU 驱动」或安装 NVIDIA 标准/Tesla 驱动。

## 串流使用（Sunshine + Moonlight）

1. 客户端安装 **Moonlight**（PC / 手机 / 电视盒均可）。
2. 浏览器打开 `https://<EIP>:47990` → 设置 Sunshine 账号密码（首登用默认，按页面提示改）。
3. Moonlight 添加主机 `<EIP>`，按提示输入 PIN 完成配对。
4. 配对后选择游戏即可低延迟串流；Steam 内游戏经 **Proton** 自动兼容运行。

> SSH 管理：`ssh ubuntu@<EIP>`（密码同 admin_password）；桌面兜底：`mstsc /v:<EIP>` 走 xrdp(3389)。

## 清理资源

```bash
terraform destroy # 同上 -var 参数
```

## FAQ

- **Moonlight 连不上？** 检查安全组 `ingress_cidr` 是否含你的出口 IP；确认 EIP 已绑定（`assign_static_ip=true`）；Sunshine 服务是否起来（`systemctl status sunshine`）。
- **Sunshine 无画面 / 黑屏？** 多为 X:0 虚拟显示未起：SSH 登入执行 `sudo nvidia-xconfig --enable-all-gpus --allow-empty-initial-configuration && sudo systemctl restart lightdm`，再重启 sunshine。
- **Steam 游戏跑不起来？** Linux 游戏走 Proton；在 Steam 设置 → 兼容性 中勾选「为所有游戏启用 Steam Play」。
- **首启动脚本没生效？** cloud-init 仅首次启动执行；已做幂等（标记文件 `/var/lib/cloud-gaming/.bootstrap_done`）。
- **想换 GPU 规格？** 改 `flavor_id` 变量，并选择与目标 Region 配额匹配的规格。
