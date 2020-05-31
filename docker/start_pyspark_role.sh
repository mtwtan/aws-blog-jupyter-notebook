#!/bin/bash 
  
config_fileloc=$1
user_sect=$2
nb_fileloc=$3
container=$4

#echo ${cred_fileloc}

if [ "$#" -ne 4 ]; then
  echo "You need to give 4 parameters: (1) Path of the AWS config file; (2) Section of the config; (3) location of notebook files; (4) Docker container image. 
  Example: ./start_pyspark.sh /home/user/.aws/ myprofile /home/user/notebook/ <docker repository>/<docker image>
  *** Please use trailing slashes ***"
  exit 1
fi

key_id="AccessKeyId"
secret_key="SecretAccessKey"
session_token="SessionToken"
profile_key="role_arn"
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_SESSION_TOKEN=""

function get_tmp_cred {
  rolearn="${1}"
  role_session_name="${2}"

  cmd="aws sts assume-role --role-arn ${rolearn} --role-session-name ${role_session_name}"
  json_return=$(${cmd})
  AWS_ACCESS_KEY_ID=$(echo ${json_return} | jq .Credentials.${key_id} | sed 's/"//g')
  AWS_SECRET_ACCESS_KEY=$(echo ${json_return} | jq .Credentials.${secret_key} | sed 's/"//g')
  AWS_SESSION_TOKEN=$(echo ${json_return} | jq .Credentials.${session_token} | sed 's/"//g')
}

function read_ini {
  sect="profile ${1}"
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

config_filepath="${config_fileloc}config"
AWS_ROLE=$(read_ini ${user_sect} ${profile_key} ${config_filepath})
SESSION_NAME=$(uuidgen)
# Generate temporary cred
get_tmp_cred ${AWS_ROLE} ${SESSION_NAME}

echo "Key: ${AWS_ACCESS_KEY_ID} | Secret: ${AWS_SECRET_ACCESS_KEY} | Session: ${AWS_SESSION_TOKEN}"

docker_cmd="/bin/bash pyspark"

docker_run="docker run -d --env AWS_ACCESS_KEY_ID='${AWS_ACCESS_KEY_ID}' --env AWS_SECRET_ACCESS_KEY='${AWS_SECRET_ACCESS_KEY}' --env AWS_SESSION_TOKEN='${AWS_SESSION_TOKEN}' -v ${cred_fileloc}:/home/glue/.aws -v ${nb_fileloc}:/home/glue/notebook -p 8000:8000 --rm ${container} ${docker_cmd}"
