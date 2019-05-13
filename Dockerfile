FROM rodolfoams/sgx-base:sgx_2.5

RUN apt-get update && apt-get install -y --no-install-recommends coreutils git wget openssh-client build-essential cmake libssl-dev libprotobuf-dev autoconf libtool libprotoc-dev libprotobuf-c-dev protobuf-c-compiler ca-certificates automake rename vim

RUN echo 'Defaults env_keep += "http_proxy https_proxy no_proxy"' >> /etc/sudoers

WORKDIR /project

COPY . .

RUN ./build.sh sgxsdk
