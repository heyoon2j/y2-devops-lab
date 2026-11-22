#!/usr/bin/env bash
set -euo pipefail

for dependency in codex python3; do
    if ! command -v "$dependency" >/dev/null; then
        printf '%s 명령을 설치한 뒤 다시 실행하세요.\n' "$dependency" >&2
        exit 1
    fi
done

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/wiki-log-sync.XXXXXXXX")
printf '테스트 파일 위치: %s\n' "$test_dir"

mkdir "$test_dir/project"
cp -R "$project_dir/.agents" "$project_dir/AGENTS.md" "$project_dir/raw" \
    "$project_dir/STATUS.md" "$test_dir/project/"
cd "$test_dir/project"

python3 - <<'PY'
from pathlib import Path

status = Path("STATUS.md")
text = status.read_text(encoding="utf-8")
original = "| T1 | M1 | <첫 작업> | <확인할 결과> | 진행 중 | — |"
assert text.count(original) == 1, "템플릿의 T1 예시 행을 찾을 수 없습니다."
status.write_text(text.replace(
    original,
    "| T1 | M1 | CSV 생성 | 샘플 배포 이력이 CSV로 반환됨 | 진행 중 | — |",
), encoding="utf-8")

Path("LOG.md").write_text("""# 업무일지

## 2026-11-22

### 작업 결과

- [T1] CSV 생성 완료. 검증용 배포 이력 1건을 요청해 CSV 헤더와 데이터 1행이 반환되는 것을 확인했습니다.
""", encoding="utf-8")
PY

cp LOG.md "$test_dir/LOG.before"

run_sync() {
    codex exec --skip-git-repo-check --sandbox workspace-write \
        '$wiki-log-sync 스킬을 사용해 2026-11-22의 가상 업무일지를 STATUS.md에 반영해줘. 테스트 복사본 안의 파일만 읽고, STATUS.md만 수정해줘.'
}

printf '\n첫 번째 반영\n'
run_sync
grep -E '^\| T1 \|.*\| 완료 \|.*LOG\.md#2026-11-22' STATUS.md
grep -E '^\| T2 \|.*\| 대기 \|' STATUS.md
grep -F '| 현재 이정표 진행률 | 1 / 2 · 50% |' STATUS.md
grep -E '^\| M1 \|.*\| 1 / 2 · 50% \|' STATUS.md
python3 .agents/scripts/update_progress.py --check
diff -u "$test_dir/LOG.before" LOG.md
cp STATUS.md "$test_dir/STATUS.after-first"

printf '\n두 번째 반영\n'
run_sync
diff -u "$test_dir/STATUS.after-first" STATUS.md
diff -u "$test_dir/LOG.before" LOG.md
printf '\n통과: 작업 완료, 진행률 50%%, 재실행 시 변경 없음.\n'
