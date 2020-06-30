#!/bin/bash
  
nb_fileloc=$1
container=$2


if [ $# -ne 2 ]; then
  echo "You need to give 2 parameters: (1) location of notebook files; (2) Docker container image.
  Example: ./start_pyspark.sh /home/user/notebook <docker repository>/<docker image>"
  exit 1
fi

echo "Key: ${AWS_ACCESS_KEY_ID} | Secret: ${AWS_SECRET_ACCESS_KEY} | Session: ${AWS_SESSION_TOKEN}"

docker_cmd="/bin/bash pyspark"

docker_run="docker run -d --env AWS_ACCESS_KEY_ID='${AWS_ACCESS_KEY_ID}' --env AWS_SECRET_ACCESS_KEY='${AWS_SECRET_ACCESS_KEY}' --env AWS_SESSION_TOKEN='${AWS_SESSION_TOKEN}' -v ${nb_fileloc}:/home/glue/notebook -p 8000:8000 --rm --name jupyter_notebook ${container} ${docker_cmd}"

eval ${docker_run}
