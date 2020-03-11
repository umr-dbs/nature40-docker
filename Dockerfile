# Use the official image as a parent image
FROM phusion/baseimage:0.11

RUN apt-get update
RUN apt-get dist-upgrade --yes

# Programs
RUN apt-get install --yes \
    clang \
    curl \
    git \
    make \
    python3-pip \
    sqlite3 \
    xxdiff \
    xxd \
    spawn-fcgi

# Install latest version of CMake
RUN pip3 install --upgrade pip && \
    pip install cmake

# Dependencies
RUN apt-get install --yes \
    libpng-dev \
    libpng++-dev \
    libjpeg-dev \
    libturbojpeg0-dev \
    libgeos-dev \
    libgeos++-dev \
    libbz2-dev \
    libcurl3-dev \
    libboost-all-dev \
    libsqlite3-dev \
    liburiparser-dev \
    libgtest-dev \
    libfcgi-dev \
    libxerces-c-dev \
    libarchive-dev \
    libproj-dev \
    valgrind \
    r-cran-rcpp \
    libpqxx-dev \
    libgdal-dev \
    libpoco-dev

WORKDIR /app

# Get MAPPING Core
ARG MAPPING_CORE_TAG=master
RUN git clone --single-branch --depth 1 --branch ${MAPPING_CORE_TAG} https://github.com/umr-dbs/mapping-core.git

# Get Nature 4.0 MAPPING MODULE
ARG MAPPING_NATURE40_TAG=master
RUN git clone --single-branch --depth 1 --branch ${MAPPING_NATURE40_TAG} https://github.com/umr-dbs/mapping-nature40.git

# Go to MAPPING Core folder
WORKDIR /app/mapping-core

# install OpenCL
RUN chmod +x docker-files/install-opencl-build.sh && \
    docker-files/install-opencl-build.sh

# Build MAPPING
RUN cmake -DMAPPING_MODULES="mapping-nature40" -DCMAKE_BUILD_TYPE=Release . && \
    make -j$(cat /proc/cpuinfo | grep processor | wc -l)

# R-server
WORKDIR /app

ARG MAPPING_R_TAG=master
RUN git clone --single-branch --depth 1 --branch ${MAPPING_R_TAG} https://github.com/umr-dbs/mapping-r-server.git
WORKDIR /app/mapping-r-server

ARG RPACKAGES='"caret","ggplot2","randomForest","raster","sp"'
ENV RPACKAGES ${RPACKAGES}

RUN apt-get install --yes r-cran-rcpp && \
    wget --no-verbose https://cran.r-project.org/src/contrib/Archive/RInside/RInside_0.2.13.tar.gz && \
    tar -xvf RInside_0.2.13.tar.gz && \
    cp docker-files/RInsideConfig.h RInside/inst/include/RInsideConfig.h && \
    R CMD INSTALL RInside && \
    R -e 'install.packages(c('$RPACKAGES'), Ncpus='$(cat /proc/cpuinfo | grep processor | wc -l)')'

RUN cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j$(cat /proc/cpuinfo | grep processor | wc -l)

# Web
RUN apt-get install --yes apache2

RUN a2enmod proxy_fcgi

RUN a2enmod deflate
RUN echo "AddOutputFilterByType DEFLATE application/json" >> /etc/apache2/mods-available/deflate.conf

WORKDIR /app

ARG WAVE_TAG=master
RUN git clone --single-branch --depth 1 --branch ${WAVE_TAG} https://github.com/umr-dbs/wave.git
WORKDIR /app/wave

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install nodejs

RUN npm install
RUN npm run build-production
COPY wave-config.json /app/wave/dist/assets/config.json

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# Inform Docker that the container is listening on the specified port at runtime.
EXPOSE 80

WORKDIR /app
COPY init.sh /app/init.sh
COPY mapping.sh /app/mapping.sh
COPY r_server.sh /app/r_server.sh
COPY init_userdb.sh /app/init_userdb.sh
RUN chmod +x init.sh mapping.sh r_server.sh init_userdb.sh

VOLUME /app/data/gdal
VOLUME /app/data/ogr
VOLUME /app/data/rastersources
VOLUME /app/data/userdb

COPY mapping-config.toml /app/mapping-core/target/bin/conf/settings.toml
COPY mapping-config.toml /app/mapping-r-server/target/bin/conf/settings.toml

WORKDIR /app
CMD /app/init.sh
