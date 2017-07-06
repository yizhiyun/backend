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

#waitting for the id_rsa.pub of all nodes has been added into the /myvol/authorized_keys file
sleep 3
cp /myvol/authorized_keys ~/.ssh/authorized_keys


: ${HDFS_HOST:=localhost}
# split each slave using "\n". For example: lh1 \nlh2 
: ${SLAVE_LIST:=localhost}
# HDFS types: namenode, checkpoint, backup, datanode
: ${HDFS_TYPE:=all}
# YARN types: resourcemanager, nodemanager, webappproxy
: ${YARN_TYPE:=all}
: ${HDFS_REPLICA:=1}

sed -i ${HADOOP_CONF_DIR}/core-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/hdfs-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/mapred-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/yarn-site.xml -e "s/{{hdfsHost}}/${HDFS_HOST}/"
sed -i ${HADOOP_CONF_DIR}/hdfs-site.xml -e "s/{{dfsReplication}}/${HDFS_REPLICA}/"

echo -e ${SLAVE_LIST} > ${HADOOP_CONF_DIR}/slaves

#start the related-type hdfs
if [ $HDFS_TYPE = "namenode" ]; then
  # format namenode
  hdfs namenode -format
  hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode
elif [ $HDFS_TYPE = "backup" ]; then
  hdfs namenode -backup;
elif [ $HDFS_TYPE = "checkpoint" ]; then
  hdfs namenode -checkpoint;
elif [ $HDFS_TYPE = "datanode" ]; then
  hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
elif [ $HDFS_TYPE = "all" ]; then
  #start hdfs integrated with namenode, secondary namenode, datanode
  start-dfs.sh
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

# fix the warn of "Unable to load native-hadoop library..."
echo "export LD_LIBRARY_PATH=\$HADOOP_HOME/lib/native" >> ~/.bashrc
source ~/.bashrc

source 
#start spark if it's master node
if [ $SPARK_TYPE = "master" ]
then
  echo -e ${WORKER_LIST} > ${SPARK_CONF_DIR}/slaves;
  $SPARK_HOME/sbin/start-all.sh;
fi

##start spark if it's slave node
#if [ $SPARK_TYPE = "slave" ]
#then
#  echo -e ${WORKER_LIST} > ${SPARK_CONF_DIR}/slaves;
#  $SPARK_HOME/sbin/start-slave.sh;
#fi

#start spark if it's master node
if [ $START_SPARK_HISTORY_SERVER = "true" ]
then
  mkdir -p /tmp/spark-events /tmp/eventlog
  $SPARK_HOME/sbin/start-history-server.sh;
fi

# if the image has installed the livy service, start this service if necessary.
if [ ${START_LIVY_SERVER} = "true" ]
then
  livy-server;
fi

tail -f /dev/null
