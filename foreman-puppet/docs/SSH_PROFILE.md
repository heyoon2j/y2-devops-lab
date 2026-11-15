# SSH 설정 Profile

## 요청한 정책과 적용 상태

| SSH 항목 | 원하는 값 | 의미 |
| --- | --- | --- |
| Banner | /etc/issue.net | 로그인 안내문 파일 경로 |
| PasswordAuthentication | yes | 패스워드 인증 허용 |
| PermitRootLogin | yes | root의 패스워드 인증을 포함한 로그인 허용 |

이 값들을 data/common.yaml에 등록했다. **profile::ssh::manage는 기본 false**다.
실제 노드에 적용하거나 SSH 서비스를 reload하지 않았다. 이미지별 Include·기존 설정과
접속 경로를 검증한 후 대상 Hiera 데이터에서 true로 활성화한다.

이 Profile은 패스워드를 생성하거나 root 계정 잠금을 해제하지 않는다. PAM·계정 상태·
AuthenticationMethods·네트워크 정책에 따라 실제 로그인이 제한될 수 있다.
Banner 파일 내용은 아직 전달받지 않았으므로 /etc/issue.net 자체는 관리하지 않는다.
활성화 전 해당 파일의 존재와 내용을 확인한다.

## 파일과 Role 연결

```text
role::base / role::devops / role::data_infra
  └── profile::base
      └── profile::ssh                 # 관리 대상 Role의 공통 기능
          ├── templates/sshd.conf.epp  # 세 옵션만 렌더링
          ├── files/validate-sshd-config.rb
          │                            # 기존 설정과 후보 파일의 조합 검사
          └── profile::service_control
                                       # 변경 시 reload, 기본 preserve

Agent에서 관리하는 파일
/etc/ssh/sshd_config.d/00-foreman-puppet.conf
/etc/puppetlabs/puppet/ssh-validation/validate-sshd-config.rb
```

기존 /etc/ssh/sshd_config 전체나 다른 drop-in은 덮어쓰지 않는다.
기존 main config가 관리 drop-in을 읽어야 하며 파일명만으로 우선순위가 보장되지는 않는다.
미관리 목표 서버도 최초 Base 단계에 이 Profile을 켜면 동일한 설정을 적용하고,
성공 후 제외 전환하면 마지막 설정이 남는다. [Role 수명 주기](ROLE_LIFECYCLE.md) 참조.

```yaml
# 실제 이미지 검증 후 적절한 CSP/환경 데이터에 활성화한다.
profile::ssh::manage: true
profile::ssh::banner: /etc/issue.net
profile::ssh::password_authentication: true
profile::ssh::permit_root_login: "yes"
profile::ssh::state_policy: preserve
profile::ssh::change_action: reload
```

전체 puppet_managed=false 또는 profile::base::manage=false이면 SSH도 제외한다.
profile::ssh::manage=false는 기존 drop-in을 삭제/원복하지 않는다.
팀별 Hiera 계층은 아직 없으므로 팀 Role 선택만으로 서로 다른 SSH 값이 조회되지는 않는다.

## 검증과 반영

1. 기존 main config의 Include를 순서대로 펼치며 관리 파일 위치에만 새 후보 내용을 넣는다.
   첫 적용에서 관리 파일이 아직 없어도 Include glob에 매칭되는 위치를 사용한다.
2. 후보가 정확히 한 번 포함되는지 확인한다. Include 누락·중복·순환이면 실패한다.
3. 조합한 임시 설정에 sshd -t를 실행한다. host key·권한·실행 디렉터리 등 OpenSSH 전제조건도 필요하다.
4. sshd -T와 root/localhost/127.0.0.1 컨텍스트의 -T -C 결과에서 세 값이 기대값인지 확인한다.
   앞선 설정이 값을 가리면 실패한다.
5. 검증 성공 시 관리 drop-in만 교체한다. 실행 중인 SSH에는 변경 이벤트로 reload한다.
   검증 실패/시간 초과 시 기존 파일을 유지하고 reload하지 않는다.

검증은 기본 15초(+강제 종료 유예 5초), 서비스 명령은 기본 60초로 제한한다.
reload 실패는 Report에 기록하며 restart fallback이나 자동 rollback은 없다.
같은 파일이 유지되는 다음 실행에는 실패한 변경 이벤트를 자동 재생하지 않는다.

현재 검증기는 **Match 블록이 있는 설정을 거부**한다. Include 안의 Match 범위를 단순히
펼치면 실제 OpenSSH와 다른 의미가 될 수 있어 별도 구현 전까지 지원하지 않는다.
Include는 절대 경로 또는 /etc/ssh 기준 상대 경로·glob를 대상으로 하며
~/$/% 확장 등은 거부한다. main_config 경로를 바꾸는 테스트에서는 그 부모를 상대 경로 기준으로 사용한다.

이 검증은 로그인·PAM·방화벽·SELinux·Banner 표시의 종단 간 성공을 보장하지 않는다.
Puppet이 관리하는 drop-in 내용 변경 때 실행되며, 다른 주체가 main config나 다른 drop-in을
변경했을 때의 상시 검사 기능은 아니다. 이 Profile이 관리하는 파일을 다른 도구가 함께 수정하지 않는다.

## OS 전제조건과 서비스 정책

| 대상 | 서비스 | 확인할 전제조건 |
| --- | --- | --- |
| Ubuntu 20.04/24.04/26.04 | ssh.service | openssh-server, Include, host key, /run/sshd 등 |
| Rocky 8/9 | sshd.service | openssh-server, Include 지원/위치, host key, SELinux 문맥 등 |

OpenSSH 패키지·host key·Include·drop-in 부모 디렉터리는 이미지/부트스트랩에서 준비한다.
이 Profile은 main config에 Include를 자동 삽입하거나 패키지를 설치하지 않는다.
Rocky 8 등에서 Include가 없으면 먼저 이미지 설정을 확인해야 하며 활성화만으로 해결되지 않는다.
Agent의 Ruby 기본 경로는 /opt/puppetlabs/puppet/bin/ruby이며 native 패키지 경로가 다르면
profile::ssh::ruby를 조정한다. /usr/bin/timeout과 /usr/bin/systemctl도 필요하다.
검증기 디렉터리의 부모 /etc/puppetlabs/puppet은 이미 존재해야 한다.

기본 preserve는 중단된 SSH를 시작하지 않는다. running을 명시하면 시작 보장 예외가 된다.
stopped는 change_action=none과 함께 사용한다. 부팅 enable/disable은 관리하지 않는다.
SSH 서비스는 이 Profile이 소유하므로 profile::services::units에 같은 ssh.service/sshd.service를
중복 선언하지 않는다. 해당 설정은 profile::ssh::* 파라미터로 조정한다.

## 검증 및 적용 순서

```sh
bundle exec ruby tests/catalog_test.rb
bundle exec ruby tests/ssh_profile_test.rb
```

Catalog 테스트는 기본 비활성·전체 제외, Ubuntu/Rocky 서비스 매핑과 요청한 값 등을 확인한다.
SSH 적용 테스트는 임시 파일과 가짜 sshd/systemctl로 변경·멱등성·드리프트·검증 실패·
Include/우선순위 거부·시간 초과·서비스 실패·제외를 검증한다.
소유권은 Catalog에서 root:root를 확인하고 격리 적용에서는 chown을 생략한다.
실제 /etc나 systemd는 변경하지 않으며 실제 OS의 OpenSSH 검증/접속 시험을 대신하지 않는다.

소수 개발 노드에서 Include·기존 옵션·Banner 파일을 확인한 뒤 noop와 실제 적용을 검증한다.
기존 세션을 유지한 채 새 일반/root 패스워드 로그인과 Banner 표시를 확인한다.
그다음 대상 범위를 확대하며 미관리 목표 노드는 성공 검증 후 제외로 전환한다.
