#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$repo_root/hw/scripts/generate_bridge_ledkey_ip.sh"
quartus_sh --flow compile "$repo_root/hw/SoCKit"
