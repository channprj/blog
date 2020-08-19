---
date: "2019-04-28T16:13:52.516470"
title: "Prometheus 및 Grafana 설치 및 설정"
description: "개인 서버들 모니터링 등의 목적으로 작은 서버를 하나 구했다. 모니터링 앱을 Docker 로 띄울까 고민하다가 서버의 성능이 낮아서 그냥 로컬에 직접 띄우기로 했다. 자주 옮겨다닐 것 같지 않아서 내린 결정인데, 만약 개인 서버들을 쿠버네티스로 관리하기 시작한다면 이사를 갈 수도 있지만 당장은 서버들의 성능이 낮아서 힘들 것 같다. 😂"
slug: "/posts/init-prometheus-grafana/"
category: "dev"
tags:
  - "dev"
  - "golang"
  - "prometheus"
  - "grafana"
  - "log"
  - "metric"
  - "data"
  - "infra"
template: "post"
draft: false
---

개인 서버들 모니터링 등의 목적으로 작은 서버를 하나 구했다. 모니터링 앱을 Docker 로 띄울까 고민하다가 서버의 성능이 낮아서 그냥 로컬에 직접 띄우기로 했다. 자주 옮겨다닐 것 같지 않아서 내린 결정인데, 만약 개인 서버들을 쿠버네티스로 관리하기 시작한다면 이사를 갈 수도 있지만 당장은 서버들의 성능이 낮아서 힘들 것 같다. 😂

## Prometheus 설치

아래와 같이 Prometheus 서비스용 사용자를 생성하자.

```bash
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
```

패키지를 직접 받아서 설치해도 되지만 귀찮음 등 여러가지의 이유로 패키지 매니져를 통해 설치하기로 했다. 아래와 같이 설치를 진행하자.

```bash
sudo apt-get update -y
sudo apt-get install -y prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager
```

### Prometheus 서비스 시작

```bash
sudo systemctl start prometheus
sudo systemctl enable prometheus
# sudo systemctl status prometheus # 서비스 확인
```

Prometheus 의 기본 포트는 9090 이다.

## Grafana 설치

공식 홈페이지에서 패키지를 직접 받아서 설치해도 상관없지만 아래와 같이 패키지 매니져에 추가 후 받아오는 방법도 있다. Grafana 는 설치 과정에서 서비스용 사용자가 생성이 되므로 미리 계정을 만들어 줄 필요는 없어보인다.

```bash
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana
```

### Grafana 서비스 시작

```bash
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
# sudo systemctl status grafana-server # 서비스 확인
```

Grafana 의 기본 포트는 3000 이다. 기타 자세한 사항은 `vim /etc/grafana/grafana.ini` 파일을 참고하면 된다.

만약 설정값을 바꾸게 되면 `reload` 옵션이 없으니 `systemctl restart grafana-server` 로 재시작을 해야 한다.

### 기본 관리자 수정

`grafana.ini` 파일을 보면 알겠지만, 기본 아이디/비밀번호가 모두 **admin** 이다. 비밀번호는 반드시 바꾸어야 하며, 새로운 계정을 생성해서 관리자로 지정한 후 admin 계정을 삭제하여도 무방하다.

admin 비밀번호 수정은 웹에서 로그인 한 후 수정을 하거나, `grafana-cli admin reset-admin-password ...` 와 같은 형태로 수정할 수 있다.

## Grafana Dashboard 추가

하나하나 패널 추가하는 것이 귀찮으면 [Grafana 공식 대시보드 모음](https://grafana.com/dashboards?dataSource=prometheus) 에서 남들이 만들어 놓은 대시보드를 직접 받을 수 있다.

여기까지 설치 및 설정이 되었다면, 아래와 같은 화면을 볼 수 있다.

![grafana-prometheus-dashboard](/img/grafana-prometheus-dashboard.png)

## Prometheus Node Exporter

Prometheus 는 하드웨어 및 커널과 관련된 메트릭 데이터를 내보내주는 **Node Exporter** 라는 기본 도구를 제공한다. \*NIX 시스템을 위한 도구라서 윈도우 서버는 지원하지 않는다. 로컬 환경의 정보를 다루다 보니 Docker 와 같은 컨테이너 형태의 설치는 권장하지 않는다. Docker 혹은 Kubernetes 메트릭 데이터 수집은 다른 도구가 있다.

### Node Exporter 설치

[공식 GitHub 저장소](https://github.com/prometheus/node_exporter)에서 받이서 설치해도 되지만, 우리는 아래와 같이 패키지 매니져를 통해 설치하자.

```bash
sudo apt install prometheus-node-exporter
```

패키지를 직접 받아서 설치하고 싶다면 공식 문서를 확인하자.

마지막으로, Prometheus 의 설정에서 수집 대상 서버 주소를 추가하고 Reload 해주면 끝난다. 아래와 같이 `/etc/prometheus/prometheus.yml` 파일의 하단을 보면 'targets' 항목이 있는데, 해당 부분에 수집할 서버의 엔드포인트를 추가해주면 된다.

```yaml
scrape_configs:
  - job_name: node
    # If prometheus-node-exporter is installed, grab stats about the local
    # machine by default.
    static_configs:
      - targets: ["localhost:9100", "new.node.com:9100"]
```

추가하고 나서는 아래와 같이 Prometheus 를 다시 로드해준다.

```bash
systemctl reload prometheus.service
```

성공적으로 추가가 됐는지 확인을 하고 싶다면 http://<PROMETHEUS_SERVER>:9090/targets 로 접속하면 아래와 같이 확인 가능하다.

![prometheus-new-node](/img/prometheus-new-node.png)

다음 번에는 Home Assistant 를 활용하여 샤오미 공기청정기 데이터를 연동하여 Grafana 로 그래프를 보여주는 글을 작성 할 것이다.

## 참고 링크

- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Prometheus - Monitoring linux host metrics with the node exporter](https://prometheus.io/docs/guides/node-exporter/)
