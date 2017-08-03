FROM hongchhe/hadoop
MAINTAINER Hongchuang <hehongchuang@hotmail.com>

# set environment variable
ENV     SPARK_HOME=/opt/spark 
ENV     SPARK_CONF_DIR=$SPARK_HOME/conf
ENV     PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin 
ENV     SPARK_VERSION=2.2.0
ENV     SPARK_URL=http://mirrors.tuna.tsinghua.edu.cn/apache
#ENV     SPARK_URL=http://www.gtlib.gatech.edu/pub/apache

RUN     mkdir -p ${SPARK_HOME} \
     && wget -q -O - ${SPARK_URL}/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz | tar -xzC ${SPARK_HOME} --strip-components=1 \
        # install python related library
     && apt-get install -y python-matplotlib \
     && pip install numpy scipy pandas requests

ENV     PYSPARK_PYTHON=/usr/bin/python
ENV     PYSPARK_DRIVER_PYTHON=ipython
ENV     PYSPARK_DRIVER_PYTHON_OPTS="notebook --no-browser --ip=* --matplotlib=inline"
ENV     PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# masterWebUI / master service / REST server / history server
EXPOSE  8080 7077 6066 18080
# workerUI / driverProgramWebUI
EXPOSE  8081 4040 4041 4042 4043 4044 4045 4046 4047 4048
# ipython notebook
EXPOSE  8888

COPY    conf/* $SPARK_CONF_DIR/
COPY    run.sh $SPARK_HOME/
COPY    jars/* $SPARK_HOME/jars/
COPY    scripts/* $SPARK_HOME/scripts/

RUN     chmod +x $SPARK_HOME/run.sh \
     && mkdir -p /myvol \
        # ssh without key
     && ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa \
     && mv $SPARK_CONF_DIR/ssh_config ~/.ssh/config 

VOLUME /myvol

WORKDIR $SPARK_HOME

ENTRYPOINT ["./run.sh"]

