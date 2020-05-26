#!/bin/bash 

cred_fileloc=$1
user_sect=$2
nb_fileloc=$3
container=$4

#echo ${cred_fileloc}

if [ "$#" -ne 4 ]; then
  echo "You need to give 4 parameters: (1) location of AWS credential file; (2) Section of the credentials; (3) location of notebook files; (4) Docker container image. 
  Example: ./start_pyspark.sh /home/user/.aws/credentials default /home/user/notebook <docker repository>/<docker image>"
  exit 1
fi

key_id="aws_access_key_id"
secret_key="aws_secret_access_key"


function read_ini {
  sect=$1
  key=$2
  fileloc=$3

  linestr=$(awk -F'=' -v section="[${sect}]" -v k="${key}"  '
  $0==section{ f=1; next }
  /\[/{ f=0; next } 
  f && $1==k{ print $0 }
  ' ${fileloc})

  if [ -z "${linestr}" ]; then
    linestr=$(awk -F' = ' -v section="[${sect}]" -v k="${key}"  '
    $0==section{ f=1; next }
    /\[/{ f=0; next } 
    f && $1==k{ print $0 }
    ' ${fileloc})

    echo ${linestr} | sed "s/${key} = //"

  else

    echo ${linestr} | sed "s/${key}=//"

  fi

}

AWS_ACCESS_KEY_ID=$(read_ini ${user_sect} ${key_id} ${cred_fileloc})
AWS_SECRET_ACCESS_KEY=$(read_ini ${user_sect} ${secret_key} ${cred_fileloc})

#echo "Key: ${AWS_ACCESS_KEY_ID} | Secret: ${AWS_SECRET_ACCESS_KEY}"

docker_cmd="/bin/bash pyspark"

docker_run="docker run -d --env AWS_ACCESS_KEY_ID='${AWS_ACCESS_KEY_ID}' --env AWS_SECRET_ACCESS_KEY='${AWS_SECRET_ACCESS_KEY}' -v ${cred_fileloc}:/home/glue/.aws -v ${nb_fileloc}:/home/glue/notebook -p 8000:8000 --rm ${container} ${docker_cmd}"


eval ${docker_run}
