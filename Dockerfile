FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Seattle
# install required packages
RUN apt-get update -y\
&& apt-get install -y g++ gcc gfortran make autoconf automake libtool\
&& apt-get install -y zlib1g-dev liblzma-dev libbz2-dev lbzip2 libgsl-dev\
&& apt-get install -y libblas-dev libx11-dev libboost1.71-all-dev git wget\
&& apt-get install -y libreadline-dev libxt-dev libpcre2-dev libcurl4-openssl-dev
# create a directory and extract R and HTSlib
RUN mkdir Tools && cd Tools\
&& wget https://cran.r-project.org/src/base/R-4/R-4.0.2.tar.gz\
&&  wget https://github.com/samtools/htslib/releases/download/1.10.2/htslib-1.10.2.tar.bz2\
&& tar -zxvf R-4.0.2.tar.gz && tar -jxvf htslib-1.10.2.tar.bz2
# compile R standalone math library
RUN cd Tools/R-4.0.2/ && ./configure\
&& cd src/nmath/standalone/ && make
# compile HTSlib
RUN cd Tools/htslib-1.10.2/ && ./configure && make
# download QTLtools
RUN cd Tools && git clone https://github.com/qtltools/qtltools.git
# update file paths and compile QTLtools
RUN cd Tools/qtltools\
&& sed -i "s|BOOST_INC=|BOOST_INC=/usr/include|" Makefile\
&& sed -i "s|BOOST_LIB=|BOOST_LIB=/usr/lib/x86_64-linux-gnu|" Makefile\
&& sed -i "s|RMATH_INC=|RMATH_INC=/Tools/R-4.0.2/src/include|" Makefile\
&& sed -i "s|RMATH_LIB=|RMATH_LIB=/Tools/R-4.0.2/src/nmath/standalone|" Makefile\
&& sed -i "s|HTSLD_INC=|HTSLD_INC=/Tools/htslib-1.10.2|" Makefile\
&& sed -i "s|HTSLD_LIB=|HTSLD_LIB=/Tools/htslib-1.10.2|" Makefile\
&& make

RUN cd Tools/qtltools && make install && exec bash

# copy binary
RUN cp Tools/qtltools/bin/QTLtools /usr/local/bin/

LABEL maintainer="Kelsey Montgomery <kelsey.montgomery@sagebase.org>"
LABEL base_image="ubuntu:20.04"
LABEL about.summary="Docker image for eQTL workflow with QTL tools and CWL"
LABEL about.license="SPDX:Apache-2.0"
