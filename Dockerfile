FROM centos/systemd:latest

LABEL maintainer="oatkrittin@gmail.com"

# Main User to user while development
ENV USER_DEV=dev
ENV HOME=/home/$USER_DEV
ENV GOPATH=${HOME}/go

ENV SINGULARITY_VERSION=3.0.0-beta.1 \
  GO_VERSION=1.11 \
  OS=linux \
  ARCH=amd64
ENV APP_HOME=/usr/local
ENV PATH=/usr/local/go/bin:${APP_HOME}/bin:${GOPATH}/bin:$PATH

# Mount Your Code to this DEV_HOME via docker volume
ENV DEV_HOME=${HOME}/Code

RUN groupadd $USER_DEV && \
  useradd dev -g $USER_DEV

# Install Dependencies
# utils like wget, which
# Development Tools, libarchive-devel needed to build Singularity
# squashfs-tools for singularity to build their images when pull image from docker:// hub
# gpgme-devel, libuuid-devel, libssl-dev, openssl-devel needed build/compiling singularity 
# java-* graphviz needed for Nextflow
RUN yum -y update && \
  yum -y groupinstall "Development Tools" && \
  yum -y install \
  wget \
  which \
  git \
  java-1.8.0-openjdk-devel \
  java-1.8.0-openjdk \
  libarchive-devel \
  libssl-dev \
  openssl-devel \
  libuuid-devel \
  gpgme-devel \
  squashfs-tools \
  graphviz \
  && \
  yum clean all && \
  rm -rf /var/cache/yum/*

# Install Golang
RUN cd /tmp && \
  wget https://dl.google.com/go/go$GO_VERSION.$OS-$ARCH.tar.gz && \
  tar -C /usr/local -xzf go$GO_VERSION.$OS-$ARCH.tar.gz && \
  rm -f go$GO_VERSION.$OS-$ARCH.tar.gz

# Install Singularity
RUN mkdir -p $GOPATH/src/github.com/sylabs && \
  cd $GOPATH/src/github.com/sylabs && \
  git clone https://github.com/sylabs/singularity.git && \
  cd singularity && \
  go get -u -v github.com/golang/dep/cmd/dep && \
  ./mconfig && \
  cd ./builddir && \
  make && make install

# Install Nextflow binary under uer dev and Configure Dir for dev
USER $USER_DEV
RUN cd $HOME && \
  wget -qO- https://get.nextflow.io | bash && \
  mkdir -p $DEV_HOME

USER root  
# Fixed Permission and move to app bin location
RUN mv ${HOME}/nextflow ${APP_HOME}/bin && \
    chmod 755 ${APP_HOME}/bin/nextflow

WORKDIR $DEV_HOME

VOLUME [ "/sys/fs/cgroup", "${DEV_HOME}" ]