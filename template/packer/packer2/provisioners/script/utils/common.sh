#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}


# 함수: OS 정보 수집
get_os() {
  if [[ ! -f /etc/os-release ]]; then
    echo "[ERROR] /etc/os-release not found" >&2
    return 1
  fi

  . /etc/os-release

  os_id="${ID,,}"
  os_ver="${VERSION_ID%%.*}"

  OS_ID=""

  case "$os_id" in
    ubuntu)
      case "$os_ver" in
        20) OS_ID="ubuntu20" ;;
        22) OS_ID="ubuntu22" ;;
        24) OS_ID="ubuntu24" ;;
        *)
          echo "[ERROR] Unsupported Ubuntu version ($os_ver)" >&2
          return 1
          ;;
      esac
      ;;
    rocky) #|rhel|centos|almalinux|fedora)
      case "$os_ver" in
        8) OS_ID="rocky8" ;;
        9) OS_ID="rocky9" ;;
        *)
          echo "[ERROR] Unsupported Rocky version ($os_ver)" >&2
          return 1
          ;;
      esac
      ;;
    *)
      echo "[ERROR] Unsupported OS (ID=${ID:-unknown}, VERSION_ID=${VERSION_ID:-unknown})" >&2
      return 1
      ;;
  esac

  echo "$OS_ID"
}

# 함수: 아키텍처 정보 수집
get_arch() {
  ARCH=$(${CMD_PREFIX} uname -m)

  case "$ARCH" in
    x86_64) ARCH_TYPE="x86_64" ;;
    aarch64) ARCH_TYPE="arm64" ;;
    *)
      echo "[ERROR] Unsupported architecture ($ARCH)" >&2
      return 1
      ;;
  esac

  echo "$ARCH_TYPE"
}

# 함수: 메인 네트워크 인터페이스 가져오기
get_network_interface() {
  local interface=""

  # 1. ip route를 이용한 방법 (가장 안정적)
  if command -v ip &>/dev/null; then
    interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [[ -n "$interface" ]]; then
      echo "$interface"
      return 0
    fi
  fi

  # 2. ifconfig를 이용한 방법 (구형 시스템)
  if command -v ifconfig &>/dev/null; then
    interface=$(ifconfig | grep -B1 "inet addr" | grep "^[a-z]" | head -n1 | awk '{print $1}')
    if [[ -n "$interface" ]]; then
      echo "$interface"
      return 0
    fi
  fi

  # 3. /sys/class/net을 이용한 방법
  if [[ -d /sys/class/net ]]; then
    for iface in $(ls /sys/class/net); do
      if [[ "$iface" != "lo" ]] && [[ -f "/sys/class/net/$iface/operstate" ]]; then
        local state=$(cat /sys/class/net/$iface/operstate)
        if [[ "$state" == "up" ]]; then
          echo "$iface"
          return 0
        fi
      fi
    done
    # 'up' 상태가 없으면 첫 번째 인터페이스 반환
    interface=$(ls /sys/class/net | grep -v lo | head -n1)
    if [[ -n "$interface" ]]; then
      echo "$interface"
      return 0
    fi
  fi

  echo "[ERROR] Cannot determine network interface" >&2
  return 1
}

# 함수: 패키지 매니저 자동 감지 및 패키지 설치
install_packages() {
  local packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "[ERROR] No packages specified" >&2
    return 1
  fi

  # dnf (Fedora, RHEL 8+)
  if command -v dnf &>/dev/null; then
    echo "[INFO] Installing packages with dnf: ${packages[@]}"
    dnf install -y "${packages[@]}"
  # yum (RHEL, CentOS, Rocky Linux, AlmaLinux)
  elif command -v yum &>/dev/null; then
    echo "[INFO] Installing packages with yum: ${packages[@]}"
    yum install -y "${packages[@]}"
  # apt-get (Debian, Ubuntu)
  elif command -v apt-get &>/dev/null; then
    echo "[INFO] Installing packages with apt-get: ${packages[@]}"
    apt-get update
    apt-get install -y "${packages[@]}"
  # pacman (Arch Linux)
  elif command -v pacman &>/dev/null; then
    echo "[INFO] Installing packages with pacman: ${packages[@]}"
    pacman -Syu --noconfirm "${packages[@]}"
  # apk (Alpine Linux)
  elif command -v apk &>/dev/null; then
    echo "[INFO] Installing packages with apk: ${packages[@]}"
    apk add --no-cache "${packages[@]}"
  # zypper (openSUSE)
  elif command -v zypper &>/dev/null; then
    echo "[INFO] Installing packages with zypper: ${packages[@]}"
    zypper install -y "${packages[@]}"
  else
    echo "[ERROR] No supported package manager found" >&2
    return 1
  fi

  if [[ $? -eq 0 ]]; then
    echo "[INFO] Package installation completed successfully"
    return 0
  else
    echo "[ERROR] Package installation failed" >&2
    return 1
  fi
}

get_repo_data() {
  local repo="$1"
  local file="$2"
  local path="$3"
  local repo_url="local"

  if [[ "$repo" == "foreman" ]] ; then
    repo_url="https://yum.theforeman.org/releases/3.11/el8/x86_64"
  elif [[ "$repo" == "epel" ]] ; then
    repo_url="https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
  fi

  wget -O "$file" "$repo_url$file"
}

enable_and_start_service() {
  local service_name="$1"
  log_info "Starting service: $service_name"

  if command -v systemctl &>/dev/null; then
    sudo systemctl enable "$service_name"
    log_success "Service $service_name enabled to start on boot"
  else
    log_error "Failed to enable service $service_name"
    return 1
  fi

  if sudo systemctl is-active --quiet "$service_name"; then
    log_info "Service $service_name is already running"
    sudo systemctl restart "$service_name"
  else
    sudo systemctl start "$service_name"
    if [[ $? -eq 0 ]]; then
      log_success "Service $service_name started successfully"
    else
      log_error "Failed to start service $service_name"
      return 1
    fi
  fi
}