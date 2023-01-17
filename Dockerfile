FROM ubuntu:20.04

MAINTAINER jmonlong@ucsc.edu

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    wget \
    gcc \ 
    tzdata \
    build-essential \
    bzip2 \
    git \
    sudo \
    less \
    g++ \
    libboost-all-dev \
    pkg-config \
    apt-transport-https software-properties-common dirmngr gpg-agent \ 
    && rm -rf /var/lib/apt/lists/*

ENV TZ=America/Los_Angeles

WORKDIR /build

## install conda
RUN wget --quiet --no-check-certificate https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda\
    && rm -f Miniconda3-latest-Linux-x86_64.sh 

ENV PATH=/opt/conda/bin:$PATH

RUN conda config --add channels conda-forge

RUN conda install python=3.7

## install dependencies
RUN conda install -c bioconda minimap2=2.18 longshot=0.4.1 samtools=1.12 racon=1.4.20 fpa=0.5 whatshap=0.18 bcftools=1.12 

## install phasebook
RUN git clone  https://github.com/jmonlong/phasebook.git

WORKDIR /build/phasebook

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    cmake \
    && rm -rf /var/lib/apt/lists/*

RUN sh install.sh

ADD filterReads.py /build/phasebook/

WORKDIR /home
