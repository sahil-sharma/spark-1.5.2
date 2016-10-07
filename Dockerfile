FROM ubuntu:14.04

MAINTAINER sahil.sharma@formcept.com

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      supervisor \
      nano \
      openssh-server \
      net-tools \
      iputils-ping \
      telnet \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install all to /opt/*
ENV OPT_DIR /opt

# Java
ENV JAVA_HOME /opt/jdk
ENV PATH $PATH:$JAVA_HOME/bin
RUN cd $OPT_DIR \
    && curl -SL -k "http://download.oracle.com/otn-pub/java/jdk/8u66-b17/jdk-8u66-linux-x64.tar.gz" -b "oraclelicense=a" \
    |  tar xz \
    && ln -s /opt/jdk1.8.0_66 /opt/jdk \
    && rm -f /opt/jdk/*src.zip \
    && echo '' >> /etc/profile \
    && echo '# JDK' >> /etc/profile \
    && echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile \
    && echo 'export PATH="$PATH:$JAVA_HOME/bin"' >> /etc/profile \
    && echo '' >> /etc/profile
# SSH keygen
RUN cd /root && ssh-keygen -t dsa -P '' -f "/root/.ssh/id_dsa" \
    && cat /root/.ssh/id_dsa.pub >> /root/.ssh/authorized_keys \
    && chmod 644 /root/.ssh/authorized_keys 

# Daemon supervisord
RUN mkdir -p /var/log/supervisor
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Daemon SSH 
RUN mkdir /var/run/sshd \
    && sed -i 's/without-password/yes/g' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config \
    && echo '    StrictHostKeyChecking no' >> /etc/ssh/ssh_config \
    && echo 'SSHD: ALL' >> /etc/hosts.allow

#Ports for spark
EXPOSE 8080 4040-4060 7077


# Spark
ENV SPARK_HOME /opt/spark
RUN cd $OPT_DIR \
    && curl -SL -k "http://d3kbcqa49mib13.cloudfront.net/spark-1.5.2-bin-hadoop2.6.tgz" \
    | tar xz \
    && rm -f spark-1.5.2-bin-hadoop2.6.tgz \
    && ln -s spark-1.5.2-bin-hadoop2.6 spark \
    && echo '' >> /etc/profile \
    && echo '# SPARK' >> /etc/profile \
    && echo "export SPARK_HOME=$SPARK_HOME" >> /etc/profile \
    && echo 'export PATH="$PATH:$SPARK_HOME/bin"' >> /etc/profile \
    && echo '' >> /etc/profile

#Spark config files
RUN cd $SPARK_HOME/conf \
    && cp spark-env.sh.template spark-env.sh \
    && echo "JAVA_HOME=/opt/jdk" >> spark-env.sh \
    && echo "SPARK_MASTER_WEBUI_PORT=8080" >> spark-env.sh \
    && echo "SPARK_WORKER_INSTANCES=1" >> spark-env.sh \
    && echo "SPARK_WORKER_CORES=2" >> spark-env.sh \
    && echo "SPARK_WORKER_MEMORY=2g" >> spark-env.sh

COPY start-spark.sh /

# Daemon
CMD ["/usr/bin/supervisord"]
