#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 && ( $# -ne 2 || $1 != --resume-raw ) ]]; then
    printf '사용법: %s [--resume-raw 테스트_폴더]\n' "$0" >&2
    exit 2
fi

for dependency in codex python3; do
    if ! command -v "$dependency" >/dev/null; then
        printf '%s 명령을 설치한 뒤 다시 실행하세요.\n' "$dependency" >&2
        exit 1
    fi
done

run_codex() {
    codex exec --skip-git-repo-check --sandbox workspace-write "$1"
}

run_raw_sync() {
    run_codex '$wiki-raw-sync 스킬로 raw/csv-meeting.md를 반영해줘. 승인된 출력 계약은 docs/INPUT_OUTPUT.md에 원본 링크와 함께 기록하고, 확정된 후속 작업 한 건은 STATUS.md 작업 표 맨 아래에 대기 상태로 등록해줘. 이정표는 미배정 상태로 유지해줘. 현재 프로젝트 내부에만 쓰고 원본은 보존해줘.'
}


check_raw_result() {
    grep -F 'deployed_at,environment,result' docs/INPUT_OUTPUT.md
    grep -F '../raw/csv-meeting.md' docs/INPUT_OUTPUT.md
    grep -E '^\|[[:space:]]*T[0-9]+[[:space:]]*\|[[:space:]]*—[[:space:]]*\|.*헤더.*\|[[:space:]]*대기[[:space:]]*\|' STATUS.md
    test "$(grep -Ec '^\|[[:space:]]*T[0-9]+[[:space:]]*\|' STATUS.md)" -eq 1
    diff -u "$test_dir/raw.before" raw/csv-meeting.md
    python3 .agents/scripts/update_progress.py --check
}

verify_raw_replay() {
    local file snapshot
    local documents=(README.md STATUS.md LOG.md docs/ARCHITECTURE.md docs/INPUT_OUTPUT.md)
    check_raw_result
    snapshot=$(mktemp -d "$test_dir/raw-replay.XXXXXXXX")
    cp "${documents[@]}" "$snapshot/"
    printf '\n같은 회의록 다시 반영\n'
    run_raw_sync
    for file in "${documents[@]}"; do
        diff -u "$snapshot/$(basename "$file")" "$file"
    done
    diff -u "$test_dir/raw.before" raw/csv-meeting.md
}

if [[ $# -eq 2 ]]; then
    test_dir=$(cd "$2" && pwd -P)
    if [[ ! -f "$test_dir/raw.before" || ! -f "$test_dir/template/csv-export-test/raw/csv-meeting.md" ]]; then
        printf '기존 테스트 폴더와 가상 CSV 회의록을 찾을 수 없습니다.\n' >&2
        exit 1
    fi
    cd "$test_dir/template/csv-export-test"
    verify_raw_replay
    printf '\n통과: wiki-raw-sync 재호출 후 변경 없음.\n'
    exit 0
fi

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/wiki-skills.XXXXXXXX")
printf '테스트 파일 위치: %s\n' "$test_dir"

for copy in template project; do
    mkdir -p "$test_dir/$copy/"{raw,src,tests}
    cp -R "$project_dir/.agents" "$project_dir/docs" "$project_dir/"*.md "$test_dir/$copy/"
done


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
    run_codex '$wiki-log-sync 스킬을 사용해 2026-11-22의 가상 업무일지를 STATUS.md에 반영해줘. 테스트 복사본 안의 파일만 읽고, STATUS.md만 수정해줘.'
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

printf '\n새 프로젝트 생성\n'
cd "$test_dir/template"
run_codex '$wiki-start 스킬로 현재 디렉터리를 템플릿으로 사용해 하위 경로 csv-export-test에 새 프로젝트를 생성해줘. 프로젝트명은 CSV 내보내기 테스트, 목표는 배포 이력 CSV 내보내기, 완료 조건은 CSV 검증 통과야. 이정표와 작업은 아직 없어. csv-export-test 내부에만 쓰고 템플릿은 수정하지 마.'
cd csv-export-test

for file in README.md AGENTS.md STATUS.md LOG.md docs/ARCHITECTURE.md docs/INPUT_OUTPUT.md \
    .agents/scripts/update_progress.py \
    .agents/skills/{wiki-start,wiki-raw-sync,wiki-log-sync}/SKILL.md; do
    test -f "$file" || { printf '누락된 파일: %s\n' "$file" >&2; exit 1; }
done
for directory in raw src tests; do
    test -d "$directory" || { printf '누락된 디렉터리: %s\n' "$directory" >&2; exit 1; }
done
grep -F 'CSV 내보내기 테스트' README.md
if grep -Eq '^\|[[:space:]]*T[0-9]+[[:space:]]*\|' STATUS.md; then
    printf '초기 STATUS.md에 작업이 등록됐습니다.\n' >&2
    exit 1
fi
python3 .agents/scripts/update_progress.py --check

printf '\n가상 회의록 반영\n'
cat > raw/csv-meeting.md <<'MEETING'
# 가상 CSV 회의록

- 승인된 출력 계약은 UTF-8 CSV이며, 헤더 순서는 deployed_at,environment,result다.
- 확정한 후속 작업은 CSV 헤더 검증 한 건이다. 완료 조건은 헤더 순서를 자동 테스트로 확인하는 것이다. 이정표 배정은 보류한다.
MEETING
cp raw/csv-meeting.md "$test_dir/raw.before"


run_raw_sync

verify_raw_replay
printf '\n통과: wiki-log-sync, wiki-start, wiki-raw-sync\n'
