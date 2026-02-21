#!/bin/bas

set -e

echo "Patch SRV"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

for script in "$SCRIPT_DIR"/*.sh; do
    script_name=$(basename "$script")

    # patch_srv.sh 파일은 제외
    if [[ "$script_name" == "patch_srv.sh" ]]; then
        continue
    fi

    # 스크립트가 실행 가능한지 확인
    if [[ -x "$script" ]]; then
        echo "▶️ Running $script_name..."
        sudo bash "$script"
        if [ $? -eq 0 ]; then
            echo "✅ $script_name completed successfully."
        else
            echo "❌ $script_name failed with exit code $?."
            exit 1
        fi
    else
        echo "⚠️ Skipping $script_name (not executable)"
    fi
done

echo "[OK] Patching SRV Completed."