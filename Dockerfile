FROM centos/systemd:latest

LABEL maintainer="oatkrittin@gmail.com"

ENV SINGULARITY_VERSION=v3.0.0-beta.1
ENV APP_HOME=/usr/local
ENV PATH=${APP_HOME}/bin:$PATH

# Main User to user while development
ENV USER_DEV=dev
ENV HOME=/home/$USER_DEV
# Mount Your Code to this DEV_HOME via docker volume
ENV DEV_HOME=${HOME}/Code

RUN groupadd $USER_DEV && \
  useradd dev -g $USER_DEV

# Install Dependencies
# utils like wget, which
# Development Tools, libarchive-devel needed to build Singularity
# squashfs-tools for singularity to build their images when pull image from docker:// hub
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
  squashfs-tools \
  graphviz \
  && \
  yum clean all && \
  rm -rf /var/cache/yum/*


# Install Singularity
RUN wget https://github.com/sylabs/singularity/archive/${SINGULARITY_VERSION}.tar.gz && \
  tar -zxvf ${SINGULARITY_VERSION}.tar.gz && \
  cd singularity-${SINGULARITY_VERSION} && \
  ./autogen.sh && \
  ./configure --prefix=$APP_HOME --sysconfdir=/etc && \
  make && make install && \
  cd .. && \
  rm -f ${SINGULARITY_VERSION}.tar.gz

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
