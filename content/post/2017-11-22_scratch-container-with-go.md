+++
type = "post"
title = "작고 가벼운 Go Docker 컨테이너 띄우기"
description = "텅 빈 스크래치 컨테이너에 Go 바이너리만 올려서 간단하면서 가볍고 빠르게 API 서버를 띄우는 내용을 다룹니다."
date = "2017-11-22"
categories = [
    "dev",
]
tags = [
    "dev",
    "golang",
    "docker",
    "container",
    "api",
    "server",
]
slug = "scratch-container-with-go"
aliases = [
    "scratch-container-with-go",
]
draft = false
+++
작년 초에 테스트를 해보고 감탄하면서 적어도 올해 초에는 튜토리얼 수준으로 한번 정리를 하려고 마음 먹었으나 정작 글을 작성하게 된 건 올해 말이 되었다. 더 늦기전에, 아예 잊어버리기 전에 정리를 하려고 이제서라도 글을 작성한다.

## 기존 컨테이너
> 여기서는 편의상 Python 과 Flask 를 사용한다.

아래는 우리 모두에게 친숙한 `Hello, World!` 를 보여주는 간단한 `app.py` 이다.

```python
from flask import Flask
app = Flask(__name__)
app.debug = True


@app.route('/')
def hello():
    return 'Hello, World!'


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
```

보통은 특정 언어로 작성한 간단한 앱을 띄울 땐 아래와 같이 Dockerfile 을 작성을 한다. 아래는 Python 과 Flask 를 예시로 작성해 본 `Dockerfile` 이다.

> requirements.txt 에는 flask 패키지가 명시되어 있다.

```dockerfile
FROM python:3
MAINTAINER YOUR NAME <your-name@example.com>
ADD app.py requirements.txt /
RUN pip install -r requirements.txt
CMD [ "python", "./app.py" ]
ENV PORT 80
EXPOSE 80
```

그리고 아래와 같이 컨테이너를 띄운다.

```bash
docker build -t flask-container .  # flask-container 라는 이미지를 만들어서
docker run -it --name flask -p 80:80 -d flask-container  # flask 라는 이름의 container 로 띄운다
```

이렇게 생성된 flask-container 의 이미지는 아래와 같다.

> Image ID 해시값은 당연히 달라질 수 있다.

```bash
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
flask-container     latest              a1392ad120dc        2 minutes ago       701MB
```

코드도 몇 줄 안 되는 간단한 API 서버를 띄웠음에도 무려 **701MB** 나 차지한다. 이유는 위의 Dockerfile 에서 명시한 `python:3` 는 `Debian Linux 8 (jessie)` 를 OS 로 사용하며, Python 실행을 위한 인터프리터 또한 설치되어 있기 때문이다. 임의로 alpine 기반의 Dockerfile 을 작성해서 띄우면 한결 가볍겠지만, 그럼에도 Python 실행을 위한 별도의 패키지들이 설치되어야 하는 건 어쩔수가 없다.

컨테이너에 설치된 패키지 등의 정보는 아래와 같이 확인이 가능하다.

```bash
docker exec -it flask bash  # bash 로 flask 컨테이너에 연결 (--interactive --tty)
cat /etc/*release*  # 컨테이너의 운영체제 배포판 확인
ls /usr/bin/ /usr/local/bin/  # 컨테이너 내부에 설치된 패키지 목록 확인
dpkg --get-selections | wc -l  # 설치된 패키지 갯수 확인
```

그러나 Go 로 작성할 경우엔 이야기가 좀 다르다. 컴파일하여 생성한 바이너리만으로도 제 기능을 하기 때문이다. 인터프리터와 같은 별도의 환경이 필요하지 않다.

## Go 바이너리 컨테이너
앞서 말했다시피 Go 는 바이너리만으로 실행이 가능하다.[^1] Go 언어로 작성된 Docker 특성상 Go 언어와의 궁합이 좋을 수 밖에 없다. 위에서 작성한 `Hello, World!` 의 기능을 하는 `main.go` 코드는 아래와 같다.

```go
package main

import (
	"io"
	"net/http"
	"log"
)

func HelloServer(w http.ResponseWriter, req *http.Request) {
	io.WriteString(w, "Hello, World!\n")
}

func main() {
	http.HandleFunc("/", HelloServer)
	log.Fatal(http.ListenAndServe(":80", nil))
}
```

이제 빌드를 해야 한다. `CGO_ENABLED` 환경변수를 **0** 으로 설정해서 cgo 가 아닌 Go 컴파일러를 사용하도록 해야 한다. `-a` Flag 는 Go 에 모든 종속성을 다시 빌드하도록 한다. 그렇지 않으면 여전히 동적으로 연결된 종속성을 가지기 때문이다. 마지막으로 Linker 와 관련하여 `-ldflags '-s'` 와 같이 빌드 옵션을 부여해서 실행 파일의 크기를 줄이는 것이 좋다.[^2]

> 이 글은 Macbook Pro Touchbar '15 (Late 2016), macOS High Sierra 기준으로 작성되었으며, 어쩌면 환경에 따라서 GOARCH 와 같은 Flag 값이 조금 달라질 수도 있다.

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-s' main.go
```

빌드를 하면 `main` 이라는 바이너리가 나오는데, 아래와 같이 Dockerfile 을 작성하여 띄워보자.

```docker
FROM scratch
MAINTAINER YOUR NAME <your-name@example.com>
ADD main /
CMD ["/main"]
ENV PORT 80
EXPOSE 80
```

그리고 아래와 같이 컨테이너를 띄운다.

```bash
docker build -t go-scratch-container .  # go-scratch-container 라는 이미지를 만들어서
docker run -it --name go-scratch -p 80:80 -d go-scratch-container  # go-scratch 라는 이름의 container 로 띄운다
```

이렇게 생성된 go-scratch-container 의 이미지는 아래와 같다.

```bash
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
go-scratch-container   latest              1e22d9716622        34 seconds ago      4.16MB
```

무려 용량이 **4.16MB** 이다! 같은 기능임에도 컨테이너 크기를 696.84MB 정도나 감소시켰다. `Alpine Linux` 용량보다도 작다. 조만간 로드/스트레스 테스트를 돌려서 벤치마킹을 해 볼 예정인데, 아무래도 컴파일/인터프리터 언어의 차이가 명확하므로 네트워크 문제를 제외한 순수한 앱 퍼포먼스는 훨씬 좋을 것이란 생각이 든다. 만약 회사에서 팀장님께 Go 스크래치 컨테이너로 API 서버를 만들자고 건의했는데 장점을 물으신다면 위의 결과를 보여드리면서 '가볍고 (용량을 덜 먹어서 저렴하고)[^3] 빠릅니다!' 라고 설득을 하면 잘 먹힐지도 모른다. 만약에 컨테이너 내부에 쉘 접속을 해야 한다거나 모니터링 ~~빨대를 꽂아서~~ 수집을 해야 한다면 눈물을 머금고 `FROM alpine` 으로 바꾼 후 관련 설정을 해주면 된다.

## 마무리
아무래도 텅 빈 스크래치 컨테이너에 바이너리를 올려서 돌리다보니 (내 기분 탓이겠지만) 조금 불안한 느낌을 지울 수가 없다. 큰 위험부담이 없는 사내 API 라면 모를까, 실 서비스에 적용을 하기엔 여러 위험요소가 있다고 본다. 오케스트레이션에 자신 있어서 문제 없이 운영할 실력이 된다면 바로 적용해도 무리는 없을 것 같지만 나는 아직 그렇지가 못하다. 그렇기에 확실히 벤치를 한번 돌려 볼 필요는 있다. 조만간 벤치를 돌려 볼 예정이다.

## 세 줄 요약
- Go 는 Docker 와 정말 궁합이 좋다.
- 스크래치 컨테이너에 Go 바이너리 던져서 돌리면 정말 가볍게 잘 돌아간다.
- 그래도 테스트를 좀 더 해봐야 할 것 같다.

----

## 참고 링크
1. [Docker Blog - DOCKER + GOLANG = <3](https://blog.docker.com/2016/09/docker-golang/)
1. [Sebest - Create a small Docker image for a GoLang binary](https://sebest.github.io/post/create-a-small-docker-image-for-a-golang-binary/)
1. [Kelsey Hightower - Building Docker Images for Static Go Binaries](https://medium.com/@kelseyhightower/optimizing-docker-images-for-static-binaries-b5696e26eb07)
1. [Runnable - Dockerize your Python Application](https://runnable.com/docker/python/dockerize-your-python-application)
1. [Runnable - Docker Tutorial](https://runnable.com/docker/)
1. [Go Docs - http](https://golang.org/pkg/net/http/)

[^1]: 물론 외부 의존성 패키지로 인한 예외가 있을 수 있다.
[^2]: 심볼 테이블 제거 등 결과물을 작게 만든다. `man ld` 로 검색해서 보면 `-s` 옵션이 Obsolete 되었다고 나오긴 하지만 Go 빌드 옵션에서는 여전히 유효한 것 같다.
[^3]: 회사에서 무언가 설득이 필요할 때 비용절감 이슈는 큰 힘이 된다.
