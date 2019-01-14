FROM centos/systemd:latest

LABEL maintainer="oatkrittin@gmail.com"

ENV VERSION=1.11.1
ENV OS=linux
ENV ARCH=amd64
ENV APP_HOME=/usr/local
ENV GOPATH=/root/go
ENV PATH=${APP_HOME}/bin:${APP_HOME}/go/bin:${PATH}:${GOPATH}/bin

# Create DEV user
RUN useradd -ms /bin/bash dev
ADD etc/sudoers.d/dev /etc/sudoers.d/dev

ADD .ssh/dev /home/dev/.ssh/id_rsa
ADD .ssh/dev.pub /home/dev/.ssh/id_rsa.pub
ADD .ssh/authorized_keys /home/dev/.ssh/authorized_keys

RUN chown -R dev:dev /home/dev/.ssh/ && \
  chmod 700 /home/dev/.ssh && \
  chmod 600 /home/dev/.ssh/* && \
  chmod 644 /home/dev/.ssh/authorized_keys && \
  mkdir -p /home/dev/code && \
  mkdir -p /home/dev/data


# Install Dependencies
# utils like wget, which
# Development Tools, libarchive-devel needed to build Singularity
# libuuid-devel openssl-devel squashfs-tools for singularity to build their images when pull image from docker:// hub
# java-* graphviz needed for Nextflow
# install sshd
RUN yum -y update && \
  yum -y groupinstall "Development Tools" && \
  yum -y install \
  wget \
  which \
  git \
  java-1.8.0-openjdk-devel \
  java-1.8.0-openjdk \
  libarchive-devel \
  squashfs-tools \
  libuuid-devel \
  openssl-devel \
  graphviz \
  openssh-server \
  && \
  yum clean all && \
  rm -rf /var/cache/yum/*

# Install Go lang
RUN wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
  tar -C $APP_HOME -xzf go$VERSION.$OS-$ARCH.tar.gz && \
  rm -f go$VERSION.$OS-$ARCH.tar.gz

# Compile && Install Singularity
RUN mkdir -p $GOPATH/src/github.com/sylabs && \
  cd $GOPATH/src/github.com/sylabs && \
  git clone https://github.com/sylabs/singularity.git && \
  cd singularity && \
  go get -u -v ${GOPATH}/src/github.com/golang/dep/cmd/dep && \
  ./mconfig && \
  make -C builddir && \
  make -C builddir install

# Install Pip to install aws-client
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
  python get-pip.py && \
  rm -f get-pip.py

# Install Nextflow binary under uer dev and Configure Dir for dev
USER dev
WORKDIR /home/dev
RUN wget -qO- https://get.nextflow.io | bash

# Install S3 cli like AWS, Minio Client(MC)
RUN pip install awscli --upgrade --user && \
    wget https://dl.minio.io/client/mc/release/linux-amd64/mc && \
    chmod u+x mc 

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
  chmod u+x Miniconda3-latest-Linux-x86_64.sh && \
  ./Miniconda3-latest-Linux-x86_64.sh -b && \
  rm -f Miniconda3-latest-Linux-x86_64.sh && \
  echo "export PATH=$PATH:/home/dev/miniconda3/bin" >> ~/.bashrc

VOLUME [ "/home/dev/data", "home/dev/code" ]

USER root

# Make nextflow globally available via softlink, trigger nextflow to load deps
RUN ln -s /home/dev/nextflow /usr/bin/nextflow && \
    ln -s /home/dev/mc  /usr/bin/mc && \
    nextflow -v

EXPOSE 22


CMD ["/usr/sbin/init"]