# Backend

Description
-----------
This repository contains many Dockerfiles for building a docker image development environment in the backend

Prerequisites
-------------
* Recommend installing the Java 8 update 20 or later, or Java 7 update 55 or later.
* install docker and docker-compose
* install git

How To Start
-----
#### 1. download the project into local machine.
```
git clone https://github.com/yizhiyun/backend.git
```
#### 2. go to spark folder
```
cd backend/spark
```
#### 3. Start docker image using docker-compose
```
docker-compose build; docker-compose up -d
```
Note: it might spend a long time to download and build image at the first time.

#### 4. Stop docker image using docker-compose
```
docker-compose stop; docker-compose rm -f
```


How To Detect
-----
#### 1. go to container to see the details using container id
```
docker exec -it spark-master0 bash
```

#### 2. check the running the logs using container id
```
docker logs spark-master0
```
#### 3. test if the spark works
```
curl http://127.0.0.1:8080
```

#### 4. test if the hdfs works
```
curl http://127.0.0.1:50070
```

#### 4. test if the livy works
```
curl http://127.0.0.1:8998
```

How To Restart if some file has been modified
-----
