#!/usr/bin/env bash
set -euo pipefail

for dependency in codex python3; do
    command -v "$dependency" >/dev/null || { printf '%s 명령이 필요합니다.\n' "$dependency" >&2; exit 1; }
done

personal_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/wiki-personal.XXXXXXXX")
printf '테스트 파일 위치: %s\n' "$test_dir"
mkdir "$test_dir/project"
cp -R "$personal_dir/.agents" "$personal_dir/"*.md "$test_dir/project/"
cd "$test_dir/project"

python3 - <<'PY'
from pathlib import Path

responsibilities = Path("RESPONSIBILITIES.md")
text = responsibilities.read_text(encoding="utf-8")
responsibilities.write_text(text.replace(
    "\n\n<!-- 작성 예시",
    "\n| R1 | CI 점검 | 메인 브랜치 CI | 매주 월요일 | 실패 원인을 기록 | — |\n\n<!-- 작성 예시",
    1,
), encoding="utf-8")

status = Path("STATUS.md")
text = status.read_text(encoding="utf-8")
for separator, row in [
    ("작업 상태와 완료 조건", "| [CSV 프로젝트 T2](PROJECT_STATUS.md) | PR 확인 | 2026-11-25 |"),
    ("ID는 `A1`", "| A1 | 안내 링크 수정 | 새 주소 열림 확인 | 진행 중 | 2026-11-27 | 2026-11-23 14:00 | 새 주소 확인 | — |"),
    ("상태는 현재 회차", "| R1 | CI 점검 | 진행 중 | 2026-11-16 | 2026-11-23 | 실패 원인 기록 | — |"),
]:
    marker = "\n\n" + separator
    assert marker in text, separator
    text = text.replace(marker, "\n" + row + marker, 1)
status.write_text(text, encoding="utf-8")

Path("PROJECT_STATUS.md").write_text("# 가상 CSV 프로젝트\n\n- T2 · 진행 중\n", encoding="utf-8")
Path("LOG.md").write_text("""# 개인 업무일지

## 2026-11-23

### 작업 결과

- [R1] CI 점검 완료. 실패 1건의 원인은 캐시 만료였고 점검 기록에 남겼습니다.
- [A1] 안내 링크 수정 완료. 새 주소가 열리는 것을 확인했습니다.

### 다음 행동

- [R1] 2026-11-30 10:00에 CI 실패 추세를 다시 점검합니다.
""", encoding="utf-8")
PY

cp LOG.md RESPONSIBILITIES.md PROJECT_STATUS.md "$test_dir/"
sync_log() {
    codex exec --skip-git-repo-check --sandbox workspace-write \
        '$wiki-personal-log-sync를 사용해 2026-11-23 가상 업무일지를 반영해줘. 이 복사본 안의 파일만 읽고 STATUS.md만 수정해줘.'
}

sync_log
python3 - <<'PY'
from pathlib import Path

rows = [line.strip().strip("|").split("|") for line in
        Path("STATUS.md").read_text(encoding="utf-8").splitlines()
        if line.strip().startswith("|")]
for task, expected in {
    "A1": {3: "완료", 4: "2026-11-27"},
    "R1": {2: "대기", 3: "2026-11-23", 4: "2026-11-30 10:00"},
}.items():
    row, = ([cell.strip() for cell in row] for row in rows if row[0].strip() == task)
    for column, value in expected.items():
        assert row[column] == value, (task, column, row[column])
    assert "LOG.md#2026-11-23" in row[-1], (task, row[-1])
PY
cp STATUS.md "$test_dir/STATUS.after-first"
sync_log
for file in LOG.md RESPONSIBILITIES.md PROJECT_STATUS.md; do
    diff -u "$test_dir/$file" "$file"
done
diff -u "$test_dir/STATUS.after-first" STATUS.md
printf '통과: 일회성 완료, 반복 업무 다음 일정, 재실행 시 변경 없음.\n'
