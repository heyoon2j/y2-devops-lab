# 위키 템플릿

[프로젝트 위키](wiki-project/README.md)와 [개인업무 위키](wiki-personal/README.md)를 복사해 사용합니다.

## 내 위키 만들기

`wiki/` 폴더에서 실행합니다.

```bash
mkdir -p workspaces
cp -R wiki-personal workspaces/my-personal
```

프로젝트를 시작하려면 Codex에서 `wiki-project/` 폴더를 열고 `$wiki-start`에 프로젝트명과 목표를 전달합니다. 이 저장소에서는 기본으로 `wiki/workspaces/<프로젝트명>/`에 생성합니다. 지정한 경로에 기존 파일이 있는 경우 스킬의 초기화 규칙을 따릅니다.

`workspaces/` 아래에는 업무일지, 원본 자료, 개인 설정을 보관합니다. 이 폴더와 그 안의 스킬 사본은 Git에서 제외됩니다.

## 공용 스킬과 로직 기여하기

공유할 변경은 해당 템플릿의 `.agents/skills/` 또는 `.agents/scripts/`에 적용하고 Git에 추가합니다. 개인 사본에서 만든 변경을 공유할 때는 필요한 스킬이나 코드만 공용 템플릿에 옮기고, 예시에는 가상 데이터를 사용합니다.
