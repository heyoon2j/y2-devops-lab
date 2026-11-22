#!/usr/bin/env python3
"""Update the derived progress cells in a project wiki's STATUS.md."""

import argparse
from collections import Counter
from pathlib import Path
import re
import stat
from tempfile import NamedTemporaryFile


STATUSES = {"대기", "진행 중", "차단", "완료", "제외"}
PIPE = re.compile(r"(?<!\\)\|")


def table_rows(lines, heading, header):
    start, = [i for i, line in enumerate(lines) if line.strip() == f"## {heading}"]
    end = next((i for i in range(start + 1, len(lines))
                if lines[i].startswith("## ")), len(lines))
    for index in range(start + 1, end):
        cells = PIPE.split(lines[index].strip())[1:-1]
        if [cell.strip() for cell in cells] == header:
            break
    else:
        raise ValueError(f"{heading}: 표 머리글을 찾을 수 없습니다.")
    if index + 1 >= end or not re.fullmatch(r"[|:\-\s]+", lines[index + 1]):
        raise ValueError(f"{heading}: 표 구분 행이 필요합니다.")

    for row in range(index + 2, end):
        line = lines[row].strip()
        if not line.startswith("|"):
            break
        cells = PIPE.split(line)
        if len(cells) != len(header) + 2 or cells[-1]:
            raise ValueError(f"{row + 1}행: 표의 열 개수를 확인하세요.")
        yield row, [cell.strip() for cell in cells[1:-1]]


def set_cell(line, column, value):
    pipes = list(PIPE.finditer(line))
    left, right = pipes[column].end(), pipes[column + 1].start()
    if line[left:right].strip() == value:
        return line
    return f"{line[:left]} {value} {line[right:]}"


def update_progress(text):
    lines = text.splitlines(keepends=True)
    milestones = {}
    for row, cells in table_rows(lines, "이정표", ["ID", "이름", "완료 조건", "목표일", "상태", "진행률"]):
        identifier = cells[0]
        if not identifier or identifier in milestones:
            raise ValueError(f"{row + 1}행: 이정표 ID가 비어 있거나 중복됩니다.")
        milestones[identifier] = row

    total, complete = Counter(), Counter()
    tasks = set()
    for row, cells in table_rows(lines, "작업 항목", ["ID", "이정표", "작업", "완료 조건", "상태", "근거"]):
        identifier, milestone, _, _, status, _ = cells
        if not identifier or identifier in tasks:
            raise ValueError(f"{row + 1}행: 작업 ID가 비어 있거나 중복됩니다.")
        tasks.add(identifier)
        if status not in STATUSES:
            raise ValueError(f"{row + 1}행: 알 수 없는 작업 상태 {status!r}")
        if milestone not in {"", "—"} and milestone not in milestones:
            raise ValueError(f"{row + 1}행: 알 수 없는 이정표 {milestone!r}")
        if milestone in milestones and status != "제외":
            total[milestone] += 1
            complete[milestone] += status == "완료"

    progress = {}
    for milestone, row in milestones.items():
        done, size = complete[milestone], total[milestone]
        percent = (200 * done + size) // (2 * size) if size else None
        progress[milestone] = f"{done} / {size} · {percent}%" if size else "미산정"
        lines[row] = set_cell(lines[row], 5, progress[milestone])

    summary = {cells[0]: (row, cells[1])
               for row, cells in table_rows(lines, "현재 상태", ["항목", "값"])}
    current = summary["현재 이정표"][1]
    if current not in {"", "—", "미정", "미산정"} and current not in progress:
        raise ValueError(f"현재 이정표를 찾을 수 없습니다: {current!r}")
    row = summary["현재 이정표 진행률"][0]
    lines[row] = set_cell(lines[row], 1, progress.get(current, "미산정"))
    return "".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("status", type=Path, nargs="?", default=Path("STATUS.md"))
    parser.add_argument("--check", action="store_true", help="파일 수정 없이 최신 상태인지 확인")
    args = parser.parse_args()
    temporary = None
    try:
        path = args.status.resolve(strict=True)
        before = path.read_bytes()
        after = update_progress(before.decode("utf-8")).encode("utf-8")
        if before == after:
            print("진행률이 최신 상태입니다.")
            return 0
        if args.check:
            print("진행률을 갱신해야 합니다.")
            return 1
        with NamedTemporaryFile(dir=path.parent, delete=False) as output:
            temporary = Path(output.name)
            output.write(after)
        temporary.chmod(stat.S_IMODE(path.stat().st_mode))
        if path.read_bytes() != before:
            raise ValueError("계산 중 STATUS.md가 변경됐습니다. 다시 실행하세요.")
        temporary.replace(path)
        print(f"진행률 갱신: {args.status}")
        return 0
    except (OSError, ValueError, KeyError) as error:
        parser.exit(2, f"{args.status}: {error}\n")
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
