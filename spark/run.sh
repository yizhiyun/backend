#!/bin/bash

#echo "export PYSPARK_PYTHON=/usr/bin/python2.7" >> ~/.bash_profile
#echo "export PYSPARK_DRIVER_PYTHON=ipython2.7" >> ~/.bash_profile
## the notebook can be accessed using the command: ipython notebook --no-browser --ip=* --matplotlib
#echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"notebook --no-browser --ip=* --matplotlib\"" >> ~/.bash_profile
#echo "export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin" >> ~/.bash_profile
: ${SPARK_TYPE:=master} 
: ${WORKER_LIST:=} 
# START_LIVY_SERVER is just for the image which has installed the livy service
: ${START_LIVY_SERVER:=false}

cat ~/.ssh/id_rsa.pub >> /myvol/authorized_keys

#start ssh service
service ssh start

# fix the warn of "Unable to load native-hadoop library..."
echo "export LD_LIBRARY_PATH=\$HADOOP_HOME/lib/native" >> /root/.bashrc
source /root/.bashrc

#waitting for the id_rsa.pub of all nodes has been added into the /myvol/authorized_keys file
sleep 3
cp /myvol/authorized_keys ~/.ssh/authorized_keys


: ${HDFS_HOST:=localhost}
: ${HDFS_WORK_BASE_DIR:="\/tmp"}
# split each slave using "\n". For example: lh1 \nlh2 
: ${SLAVE_LIST:=localhost}
# HDFS types: namenode, checkpoint, backup, datanode
: ${HDFS_TYPE:=all}
# YARN types: resourcemanager, nodemanager, webappproxy
: ${YARN_TYPE:=all}
: ${HDFS_REPLICA:=1}

sed -i ${HADOOP_CONF_DIR}/core-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/core-site.xml -e "s/{{hdfsWorkBaseDir}}/${HDFS_WORK_BASE_DIR}/"
sed -i ${HADOOP_CONF_DIR}/hdfs-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/mapred-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/yarn-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/hdfs-site.xml -e "s/{{dfsReplication}}/${HDFS_REPLICA}/"

echo -e ${SLAVE_LIST} > ${HADOOP_CONF_DIR}/slaves

#start the related-type hdfs
if [ $HDFS_TYPE = "namenode" ]; then
  # format namenode
  hdfs namenode -format  -nonInteractive
  hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode
elif [ $HDFS_TYPE = "backup" ]; then
  hdfs namenode -backup;
elif [ $HDFS_TYPE = "checkpoint" ]; then
  hdfs namenode -checkpoint;
elif [ $HDFS_TYPE = "datanode" ]; then
  hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
elif [ $HDFS_TYPE = "all" ]; then
  #start hdfs integrated with namenode, secondary namenode, datanode
  #start-dfs.sh
  # format namenode
  hdfs namenode -format -nonInteractive
  hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode
  hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
else
  echo "Do nothing for hdfs service."
fi


: ${SPARK_RECOVERY_MODE:=NONE}
: ${SPARK_ZK_URL:=None}
: ${SPARK_ZK_DIR:=None}
: ${SPARK_MASTER_URL:="local"}
#: ${SPARK_MASTER_URL:="spark:\/\/master:7077"}
: ${START_SPARK_HISTORY_SERVER:="false"}
: ${SPARK_EVENTLOG_DIR:="file:\/tmp\/eventlog"}
#: ${SPARK_EVENTLOG_DIR:="hdfs:\/\/spark-master0:9000\/spark\/eventlog"}
: ${SPARK_HISTORYLOG_DIR:="file:\/tmp\/spark-events"}

sed -i ${SPARK_CONF_DIR}/spark-defaults.conf -e "s/{{sparkRecoveryMode}}/${SPARK_RECOVERY_MODE}/"
sed -i ${SPARK_CONF_DIR}/spark-defaults.conf -e "s/{{sparkZKUrl}}/${SPARK_ZK_URL}/"
sed -i ${SPARK_CONF_DIR}/spark-defaults.conf -e "s/{{sparkZKDir}}/${SPARK_ZK_DIR}/"
sed -i ${SPARK_CONF_DIR}/spark-defaults.conf -e "s/{{sparkMaster}}/${SPARK_MASTER_URL}/"
sed -i ${SPARK_CONF_DIR}/spark-defaults.conf -e "s/{{sparkEventLogDir}}/${SPARK_EVENTLOG_DIR}/"
sed -i ${SPARK_CONF_DIR}/spark-defaults.conf -e "s/{{sparkHistoryLogDir}}/${SPARK_HISTORYLOG_DIR}/"

#set the embed hive configuration.
echo "spark.sql.warehouse.dir=hdfs://${HDFS_HOST}:9000/user/hive/warehouse" >> ${SPARK_CONF_DIR}/spark-defaults.conf 
sed -i ${SPARK_CONF_DIR}/hive-site.xml -e "s/\${system:java.io.tmpdir}/\/opt\/spark\/local/g"
sed -i ${SPARK_CONF_DIR}/hive-site.xml -e "s/\${system:user.name}/hive/g"
echo -e ${WORKER_LIST} > ${SPARK_CONF_DIR}/slaves;

#start spark if it's master node
if [ $SPARK_TYPE = "master" ]
then
  $SPARK_HOME/sbin/start-master.sh;
  $SPARK_HOME/sbin/start-slaves.sh;
fi

##start spark if it's slave node
#if [ $SPARK_TYPE = "slave" ]
#then
#  $SPARK_HOME/sbin/start-slave.sh ${SPARK_MASTER_URL//\\/};
#fi

#start spark if it's master node
if [ $START_SPARK_HISTORY_SERVER = "true" ]
then
  if [[ ${SPARK_EVENTLOG_DIR} == hdfs* ]];
  then
    hdfs dfs -mkdir -p ${SPARK_EVENTLOG_DIR//\\/}
  else
    mkdir -p ${SPARK_EVENTLOG_DIR//\\/}
  fi

  if [[ ${SPARK_HISTORYLOG_DIR} == hdfs* ]];
  then
    hdfs dfs -mkdir -p ${SPARK_HISTORYLOG_DIR//\\/}
  else
    mkdir -p ${SPARK_HISTORYLOG_DIR//\\/}
  fi
  $SPARK_HOME/sbin/start-history-server.sh;
fi

# if the image has installed the livy service, start this service if necessary.
if [ ${START_LIVY_SERVER} = "true" ]
then
  livy-server start;
  sleep 6;
  python $SPARK_HOME/scripts/livysessions.py add;
fi

tail -f /dev/null
