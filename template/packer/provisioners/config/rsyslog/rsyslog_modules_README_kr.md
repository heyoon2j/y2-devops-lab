# rsyslog 모듈 가이드

## 현재 설정에서 사용하는 핵심 모듈

현재 구성은 운영 환경에서 가장 기본적이면서도 안전한 3개의 모듈을 사용합니다.

---

## 1. imuxsock

```conf
module(load="imuxsock")
```

### 역할

로컬 UNIX socket 기반 syslog 로그를 수집합니다.

### 입력 경로

```text
/dev/log
```

### 대표적으로 수집되는 로그

- sshd
- sudo
- cron
- 대부분의 로컬 시스템 서비스

### 흐름

```text
application -> /dev/log -> rsyslog
```

### 왜 필요한가

Linux 기본 syslog 입력 방식이므로 거의 항상 활성화합니다.

---

## 2. imjournal

```conf
module(load="imjournal")
```

### 역할

systemd journal 로그를 수집합니다.

### 입력 경로

```text
journalctl / systemd journal
```

### 대표적으로 수집되는 로그

- kubelet
- containerd
- systemd unit
- docker
- cloud-init

### 흐름

```text
systemd journal -> rsyslog
```

### 왜 필요한가

Ubuntu / Rocky Linux의 많은 서비스는 journal에 직접 로그를 기록합니다.

이 모듈이 없으면 일부 로그가 누락될 수 있습니다.

---

## 3. omkafka

```conf
module(load="omkafka")
```

### 역할

Apache Kafka로 로그를 전송합니다.

### 분류

출력(Output) 모듈입니다.

### 흐름

```text
rsyslog -> Kafka broker
```

### 사용 위치

```conf
action(
  type="omkafka"
)
```

### 왜 필요한가

Kafka topic으로 로그를 보내기 위해 필요합니다.

---

## 모듈 이름 규칙

## Input 모듈 (im*)

입력 모듈은 로그를 어디서 가져오는지 결정합니다.

예시:

- imuxsock
- imjournal
- imfile
- imtcp

---

## Output 모듈 (om*)

출력 모듈은 로그를 어디로 보낼지 결정합니다.

예시:

- omfile
- omkafka
- omfwd

---

## Message Modify 모듈 (mm*)

로그를 가공하거나 변환합니다.

예시:

- mmjsonparse

---

## 실무에서 자주 추가되는 모듈

## imfile

파일 기반 로그를 읽습니다.

사용 예:

- 애플리케이션 로그
- 컨테이너 로그 파일

---

## omfile

파일로 로그를 저장합니다.

사용 예:

- /var/log/messages
- /var/log/syslog

---

## mmjsonparse

JSON 로그를 필드 단위로 파싱합니다.

Kafka / Elasticsearch 연동 시 자주 사용합니다.

---

## 패키지 설치

## Debian / Ubuntu

```bash
apt install rsyslog rsyslog-kafka
```

## RedHat / Rocky

```bash
dnf install rsyslog rsyslog-kafka
```

---

## 설정 검증

```bash
rsyslogd -N1
```

---

## 운영 추천 최소 구성

현재 운영에서 가장 기본적인 안전 구성:

- imuxsock
- imjournal
- omkafka

이 조합으로 다음을 모두 처리할 수 있습니다.

- 로컬 시스템 로그
- systemd 로그
- Kafka 전송
