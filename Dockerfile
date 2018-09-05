FROM centos:7

LABEL maintainer="oatkrittin@gmail.com"

ENV SINGULARITY_VERSION=2.6.0
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
# squashfs-tools for singularity to build their images
# java-* needed for Nextflow
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
  && \
  yum clean all && \
  rm -rf /var/cache/yum/*


# Install Singularity
RUN git clone https://github.com/singularityware/singularity.git && \
  cd singularity && \
  git fetch --all && \
  git checkout $SINGULARITY_VERSION && \
  ./autogen.sh && \
  ./configure --prefix=$APP_HOME && \
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
VOLUME [ "${DEV_HOME}" ]
