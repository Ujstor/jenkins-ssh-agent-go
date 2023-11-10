FROM jenkins/ssh-agent


WORKDIR /home/jenkins

COPY . .

RUN apt update && \
    apt -y install jq ca-certificates gnupg software-properties-common wget curl git python3-pip python3.11 python3-venv python3.11-venv python3-dev python3.11-dev unzip zip libcurl4-openssl-dev libssl-dev

RUN wget https://golang.org/dl/go1.20.2.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.20.2.linux-amd64.tar.gz

RUN wget https://github.com/go-task/task/releases/download/v3.31.0/task_linux_amd64.tar.gz && \
    tar -xzf task_linux_amd64.tar.gz && \
    cp task /usr/bin/task && \
    chmod +x /usr/bin/task

ENV PATH="/usr/local/go/bin:${PATH}:/home/jenkins/bin"
ENV GOPATH="/home/jenkins/go"
ENV PATH="${PATH}:${GOPATH}/bin"

RUN go install github.com/jstemmer/go-junit-report/v2@latest 

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update && \
    apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-cli

RUN chmod +x docker_tag.sh

CMD ["/bin/sh", "-c", "setup-sshd && dockerd --host=unix:///var/run/docker.sock"]

#docker run -it -v /var/run/docker.sock:/var/run/docker.sock <image> /bin/bash