# versioned base image
FROM ubuntu:20.04

# -- metadata --
LABEL maintainer="Kelsey Montgomery <kelsey.montgomery@sagebase.org>"
LABEL base_image="ubuntu:20.04"
LABEL about.summary="Docker image for eQTL workflow with QTL tools and CWL"
LABEL about.license="SPDX:Apache-2.0"

# avoid interactive prompts when installing required packages
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Seattle

# install required packages
RUN apt-get update --yes \
 && apt-get install --yes \
    g++ \
    gcc \
    gfortran \
    make \
    autoconf \
    automake \
    libtool \
    zlib1g-dev \
    liblzma-dev \
    libbz2-dev \
    lbzip2 \
    libgsl-dev \
    libblas-dev \
    libx11-dev \
    libboost1.71-all-dev \
    git \
    wget \
    libreadline-dev \
    libxt-dev \
    libpcre2-dev \
    libcurl4-openssl-dev \
    python3-venv python3-pip \
    tabix

# install synapseclient
RUN pip3 install synapseclient 

# create a directory and extract R and HTSlib
WORKDIR Tools

RUN wget https://cran.r-project.org/src/base/R-4/R-4.0.2.tar.gz \
    https://github.com/samtools/htslib/releases/download/1.10.2/htslib-1.10.2.tar.bz2 \
 && tar -zxvf R-4.0.2.tar.gz \
 && tar -jxvf htslib-1.10.2.tar.bz2

# compile R standalone math library
RUN cd R-4.0.2/ && ./configure \
 && cd src/nmath/standalone/ && make

# compile HTSlib
RUN cd htslib-1.10.2/ && ./configure && make

# download QTLtools
RUN git clone -b 1.3.1 https://github.com/qtltools/qtltools

# update file paths and compile QTLtools
RUN cd qtltools \
 && sed -i "s|BOOST_INC=|BOOST_INC=/usr/include|" Makefile \
 && sed -i "s|BOOST_LIB=|BOOST_LIB=/usr/lib/x86_64-linux-gnu|" Makefile \
 && sed -i "s|RMATH_INC=|RMATH_INC=/Tools/R-4.0.2/src/include|" Makefile \
 && sed -i "s|RMATH_LIB=|RMATH_LIB=/Tools/R-4.0.2/src/nmath/standalone|" Makefile \
 && sed -i "s|HTSLD_INC=|HTSLD_INC=/Tools/htslib-1.10.2|" Makefile \
 && sed -i "s|HTSLD_LIB=|HTSLD_LIB=/Tools/htslib-1.10.2|" Makefile \
 && make

RUN cd qtltools && make install && exec bash

# copy binary
RUN cp qtltools/bin/QTLtools /usr/local/bin/

# extract and compile bcftools
RUN wget https://github.com/samtools/bcftools/releases/download/1.10/bcftools-1.10.tar.bz2 \
     -O bcftools.tar.bz2 \
 && tar -xjvf bcftools.tar.bz2
 && cd bcftools-1.10
 && make
 && make prefix=/usr/local/bin install
 && ln -s /usr/local/bin/bin/bcftools /usr/bin/bcftools

