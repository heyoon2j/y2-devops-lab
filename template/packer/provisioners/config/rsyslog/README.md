# Linux System Log Management README

## 개요

시스템 로그는 rsyslog를 통해 관리한다.

rsyslog는 다음 역할을 수행한다.

- 시스템 로그 수집
- facility별 로그 분리
- 파일 저장
- 외부 시스템 전송 (예: Kafka)
- logrotate 연계

---

## 로그 수집 구조

application / kernel / journal
        ↓
      rsyslog
        ↓
 local file / external output

---

## OS별 기본 로그 구조

| OS | 기본 로그 관리 | rsyslog 설치 후 로그 파일 | logrotate 설정 파일 |
|----|----|----|----|
| Ubuntu | /var/log/syslog | /var/log/syslog | /etc/logrotate.d/rsyslog |
| Rocky Linux | /var/log/logmessages | /var/log/messages | /etc/logrotate.d/syslog |
| Amazon Linux 2023 | journal 중심 | /var/log/messages | /etc/logrotate.d/rsyslog |

---

# Ubuntu

## 기본 로그 파일

/var/log/syslog

## 시스템 로그 관리 방식

systemd journal + rsyslog

## 주요 로그 파일

- /var/log/syslog
- /var/log/auth.log
- /var/log/mail.log

---

# Rocky Linux

## 기본 로그 파일

/var/log/messages

## 시스템 로그 관리 방식

systemd journal + rsyslog

## 주요 로그 파일

- /var/log/messages
- /var/log/secure
- /var/log/cron
- /var/log/maillog

---

# Amazon Linux 2023

## 기본 로그 관리 방식

journal 중심

## 기본 확인 방법

journalctl

## rsyslog 설치 후

rsyslog가 journal을 읽어 /var/log/messages 생성

## 주요 특징

messages 파일은 기본 로그 파일이 아니라 rsyslog output 결과

---

# logrotate

## Ubuntu / Amazon Linux 2023

/etc/logrotate.d/rsyslog

## Rocky Linux

/etc/logrotate.d/syslog

---

# 운영 시 로그 확인 우선순위

1. local log file
2. journalctl
3. external collector

---

# 핵심 운영 포인트

파일은 결과물이고 실제 source는 journal + socket 이다

---

# rsyslog 핵심 모듈

## imuxsock

/dev/log 기반 local syslog 입력

주요 대상:

- sshd
- sudo
- cron

## imjournal

systemd journal 입력

주요 대상:

- kubelet
- containerd
- docker
- cloud-init

## omkafka

Kafka 전송 output module

---

# rsyslog 추가 주요 모듈

## imklog

kernel log 입력

입력 source:

- /proc/kmsg

주요 대상:

- kernel panic
- OOM killer
- disk I/O error

## imfile

파일 기반 로그 입력

예시:

input(
  type="imfile"
  File="/var/log/app.log"
  Tag="myapp"
)

용도:

- custom app log
- container log

## omfile

파일 출력 module

예시:

action(
  type="omfile"
  file="/var/log/custom.log"
)

용도:

- 특정 로그 별도 저장

---

# Kafka 연동 구조

system log → rsyslog → Kafka

Kafka 사용 시 JSON template 사용 권장

주요 topic 예시:

- system-log
- k8s-log

---

# Kubernetes 로그 정책

## stop 방식

k8s noisy log 제외

예:

- kubelet
- containerd
- kube-proxy

## split 방식

k8s-log topic 별도 전송

권장 운영 방식:

production = split

---

# queue 설정

Kafka burst 대응을 위해 queue 설정 권장

예시:

main_queue(
  queue.type="LinkedList"
  queue.size="50000"
)

---

# 운영 원칙

- local file 유지
- Kafka는 추가 전송
- noisy log 분리
- 최소 모듈 유지
