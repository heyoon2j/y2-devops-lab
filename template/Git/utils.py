def init_git():
    pass
"""
!/bin/bash
################ Configuation ################
user_name=""
user_email=""
core_editor="vim"
core_pager="cat"

git config --global user.name $user_name                # 전역 사용자 설정
git config --global user.email $user_email              # 전역 이메일 설정
git config --global core.editor $core_editor            # 전역 Editor 설정
git config --global core.pager $core_pager              # Git은 log 또는 diff 같은 명령의 메시지를 출력할 때 페이지로 나누어 보여준다. 기본으로 사용하는 명령은 less 다. more 를 더 좋아하면 more 라고 설정한다. 페이지를 나누고 싶지 않으면 빈 문자열로 설정한다.


################ Initialization ################
clone=true

origin_name="origin"
origin_url=""
origin_main="main"

upstream_name="upstream"
upstream_url=""
upstream_main="main"

if [ "$clone" = false ]; then
    # 1) init
    git init
    git remote add $origin_name $origin_url
    git push -u $origin_name $origin_main
else
    # 2) clone
    git clone $origin_url
fi

if [ -z "$upstream_url" ]; then
    echo "upstream_url이 설정되지 않았습니다."
    exit 1                                  # 스크립트 종료
else
    git remote add $upstream_name $upstream_url
    echo "upstream_url 설정 완료 : $upstream_url"
fi
"""


def sync_upstream_repo():
    pass
"""
origin_name="origin"
origin_branch="main"

upstream_name="upstream"
upstream_branch="main"


git fetch $upstream_name

git checkout $origin_branch

git merge $upstream_name/$upstream_branch
"""
