# use the centos base image
FROM centos:7
MAINTAINER Tour He, hetaohai@theinitium.com

ENV JAVA_VERSION 8u111
ENV BUILD_VERSION b14

# Upgrading system
RUN yum -y upgrade
RUN yum -y install wget

# Downloading Java
RUN wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$BUILD_VERSION/jdk-$JAVA_VERSION-linux-x64.rpm" -O /tmp/jdk-8-linux-x64.rpm

RUN yum -y install /tmp/jdk-8-linux-x64.rpm

RUN alternatives --install /usr/bin/java jar /usr/java/latest/bin/java 200000
RUN alternatives --install /usr/bin/javaws javaws /usr/java/latest/bin/javaws 200000
RUN alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000

ENV JAVA_HOME /usr/java/latest


#ENV TSDB_VERSION 2.2.1
#ENV TSDB_VERSION_RPM 2.2.1
ENV TSDB_VERSION 2.3.0
ENV TSDB_VERSION_RPM 2.3.0
ENV HBASE_VERSION 1.1.3
ENV PATH $PATH:/usr/java/latest/bin/

RUN mkdir -p /opt/bin/

RUN mkdir -p /opt/opentsdb
WORKDIR /opt/opentsdb/
#RUN wget https://github.com/OpenTSDB/opentsdb/releases/download/v${TSDB_VERSION}/opentsdb-${TSDB_VERSION}.rpm \
RUN wget https://github.com/OpenTSDB/opentsdb/releases/download/v${TSDB_VERSION}/opentsdb-${TSDB_VERSION_RPM}.rpm \
  && yum localinstall opentsdb-${TSDB_VERSION_RPM}.rpm -y \
  && rm opentsdb-${TSDB_VERSION_RPM}.rpm

#Install HBase and scripts
RUN mkdir -p /data/hbase /root/.profile.d /opt/downloads

WORKDIR /opt/downloads
RUN wget -O hbase-${HBASE_VERSION}.bin.tar.gz http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz && \
    tar xzvf hbase-${HBASE_VERSION}.bin.tar.gz && \
    mv hbase-${HBASE_VERSION} /opt/hbase && \
    rm hbase-${HBASE_VERSION}.bin.tar.gz

ADD docker/hbase-site.xml /opt/hbase/conf/
ADD docker/start_opentsdb.sh /opt/bin/
ADD docker/create_tsdb_tables.sh /opt/bin/
ADD docker/start_hbase.sh /opt/bin/
ADD docker/start_all.sh /opt/bin/

RUN for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
    do \
        sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
    done


RUN mkdir -p /etc/services.d/hbase /etc/services.d/tsdb
RUN ln -s /opt/bin/start_hbase.sh /etc/services.d/hbase/run
RUN ln -s /opt/bin/start_opentsdb.sh /etc/services.d/tsdb/run

RUN chmod +x /opt/bin/start_all.sh 
RUN ln -s /opt/bin/start_all.sh /etc/profile.d/start_all.sh

#TSDB configure
RUN echo tsd.storage.fix_duplicates=true >> /usr/share/opentsdb/etc/opentsdb/opentsdb.conf

EXPOSE 60000 60010 60030 4242 16010

VOLUME ["/data/hbase", "/tmp"]
