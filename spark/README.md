# spark
$ docker run --rm -p 8080:8080 -p 18081:8081 -p 7077:7077 -p 6066:6066 --name=spark1 -d spark1
$ docker exec -it spark1 bash

Examples:
1. Test if spark work normal using the following command
$ bin/run-example SparkPi 10
OR 
$ bin/run-example GroupByTest
2. run python script as below
/opt/spark/bin/spark-submit /opt/spark/examples/src/main/python/wordcount.py README.md
3. find the data/spam.data from "git clone https://github.com/xsankar/fdps-vii.git"
OR "wget https://github.com/xsankar/fdps-vii/blob/master/data/spam.data"
