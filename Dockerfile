# Base image, see https://hub.docker.com/r/rocker/rstudio
FROM rocker/tidyverse:3.5.3

# Install Oracle JDK 1.8.0_212 =================

#  https://github.com/frekele/docker-java/blob/jdk8u212/Dockerfile

# Set environment variables for program versions
ENV JDK_VERSION=8
ENV JDK_UPDATE=212
ENV JDK_BUILD=b10
ENV JDK_DISTRO_ARCH=linux-x64

ENV JCE_FOLDER=UnlimitedJCEPolicyJDK$JDK_VERSION
ENV JDK_FOLDER=jdk1.$JDK_VERSION.0_$JDK_UPDATE
ENV JDK_VERSION_UPDATE=$JDK_VERSION'u'$JDK_UPDATE
ENV JDK_VERSION_UPDATE_BUILD=$JDK_VERSION_UPDATE'-'$JDK_BUILD
ENV JDK_VERSION_UPDATE_DISTRO_ARCH=$JDK_VERSION_UPDATE'-'$JDK_DISTRO_ARCH

ENV JAVA_HOME=/opt/java
ENV JRE_SECURITY_FOLDER=$JAVA_HOME/jre/lib/security
ENV SSL_TRUSTED_CERTS_FOLDER=/opt/ssl/trusted

# Change to tmp folder
WORKDIR /tmp

# Download and extract jdk to opt folder
RUN wget --no-check-certificate https://github.com/frekele/oracle-java/releases/download/${JDK_VERSION_UPDATE_BUILD}/jdk-${JDK_VERSION_UPDATE_DISTRO_ARCH}.tar.gz \
    && wget --no-check-certificate https://github.com/frekele/oracle-java/releases/download/${JDK_VERSION_UPDATE_BUILD}/jdk-${JDK_VERSION_UPDATE_DISTRO_ARCH}.tar.gz.md5 \
    && echo "$(cat jdk-${JDK_VERSION_UPDATE_DISTRO_ARCH}.tar.gz.md5) jdk-${JDK_VERSION_UPDATE_DISTRO_ARCH}.tar.gz" | md5sum -c \
    && tar -zvxf jdk-${JDK_VERSION_UPDATE_DISTRO_ARCH}.tar.gz -C /opt \
    && ln -s /opt/${JDK_FOLDER} /opt/java \
    && rm -f jdk-${JDK_VERSION_UPDATE_DISTRO_ARCH}.tar.gz \
    && rm -f jdk-${JDK_VERSION_UPDATE_DISTRO_ARCH}.tar.gz.md5

# Download zip file with java cryptography extension and unzip to jre security folder
RUN wget --no-check-certificate https://github.com/frekele/oracle-java/releases/download/oracle_jce${JDK_VERSION}/jce_policy-${JDK_VERSION}.zip \
    && unzip jce_policy-${JDK_VERSION}.zip \
    && cp ${JCE_FOLDER}/*.jar ${JRE_SECURITY_FOLDER} \
    && rm -f jce_policy-${JDK_VERSION}.zip \
    && rm -rf ${JCE_FOLDER}
    
# Add executables to path
RUN update-alternatives --install "/usr/bin/java" "java" "/opt/java/bin/java" 1 && \
    update-alternatives --set "java" "/opt/java/bin/java" && \
    update-alternatives --install "/usr/bin/javac" "javac" "/opt/java/bin/javac" 1 && \
    update-alternatives --set "javac" "/opt/java/bin/javac" && \
    update-alternatives --install "/usr/bin/keytool" "keytool" "/opt/java/bin/keytool" 1 && \
    update-alternatives --set "keytool" "/opt/java/bin/keytool"

# Create trusted ssl certs folder
RUN mkdir -p $SSL_TRUSTED_CERTS_FOLDER

# Mark as volume
VOLUME $SSL_TRUSTED_CERTS_FOLDER

# Configure Java Parameters for R
RUN cd $R_HOME && R CMD javareconf

# Change to root folder
WORKDIR /root

# End Oracle JDK 1.8.0_212 ===================

# Install rJava =====================
# https://stackoverflow.com/questions/40109139/error-installing-rjava-makefile-all38-recipe-for-target-libjri-so-failed
# https://github.com/s-u/rJava/issues/161#issuecomment-428269293

RUN sudo apt-get install libbz2-dev libpcre3-dev liblzma-dev zlib1g-dev libomp-dev -y

RUN sudo apt-get fonts-noto-cjk -y

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN R -e 'install.packages("rJava")'
# End rJava =====================