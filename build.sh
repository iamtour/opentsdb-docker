#!/bin/sh
docker build -t initiumlab/opentsdb:latest .

#deploy
docker login
docker push initiumlab/opentsdb:latest
docker logout

#run
docker pull initiumlab/opentsdb:latest
docker run --name opentsdb -it -p 4242:4242 -v /opt/lion-stock/opentsdb -d initiumlab/opentsdb:latest

