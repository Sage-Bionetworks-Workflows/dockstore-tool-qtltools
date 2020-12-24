FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Seattle
RUN apt-get update -y\
&& apt-get install -y g++ gcc gfortran make autoconf automake libtool\
&& apt-get install -y zlib1g-dev liblzma-dev libbz2-dev lbzip2 libgsl-dev\
&& apt-get install -y libblas-dev libx11-dev libboost1.71-all-dev git wget\
&& apt-get install -y libreadline-dev libxt-dev libpcre2-dev libcurl4-openssl-d$

RUN mkdir Tools && cd Tools\
&& wget https://cran.r-project.org/src/base/R-4/R-4.0.2.tar.gz\
&& wget https://github.com/samtools/htslib/releases/download/1.10.2/htslib-1.10$
&& tar -zxvf R-4.0.2.tar.gz && tar -jxvf htslib-1.10.2.tar.bz2
# compile R standalone math library
RUN cd Tools/R-4.0.2/ && ./configure\
&& cd src/nmath/standalone/ && make
# compile HTSlib
RUN cd Tools/htslib-1.10.2/ && ./configure && make
# download QTLtools
RUN cd Tools && git clone https://github.com/qtltools/qtltools.git
# update file paths and make
RUN cd Tools/qtltools\
&& BOOST_INC=/usr/include\
&& BOOST_LIB=/usr/lib/x86_64-linux-gnu\
&& RMATH_INC=${HOME}/Tools/R-4.0.2/src/include\
&& RMATH_LIB=${HOME}/Tools/R-4.0.2/src/nmath/standalone\
&& HTSLD_INC=${HOME}/Tools/htslib-1.10.2\
&& HTSLD_LIB=${HOME}/Tools/htslib-1.10.2
# append to path
ENV PATH=${PATH}:./bin/:./scripts/
ENV MANPATH=${MANPATH}:./man/
ENV PATH=${PATH}:././Tools/doc/QTLtools_bash_autocomplete.bash
# compile QTLtools
RUN cd Tools/qtltools && make

LABEL maintainer="Kelsey Montgomery <kelsey.montgomery@sagebase.org>"
LABEL base_image="ubuntu:20.04"
LABEL about.summary="Docker image for eQTL workflow with QTL tools and CWL"
LABEL about.license="SPDX:Apache-2.0"
