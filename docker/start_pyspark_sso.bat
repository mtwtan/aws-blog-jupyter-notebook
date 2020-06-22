@echo off
SETLOCAL EnableDelayedExpansion

SET /A ARGS_COUNT=0    
FOR %%A in (%*) DO SET /A ARGS_COUNT+=1    

echo %ARGS_COUNT%
IF %ARGS_COUNT% LSS 3 (
    echo "Please provide 3 parameters -- credentials file path (ex: C:\Users\<user>\.aws) and notebook directory and container name"
    EXIT /B
)


SET CRED_FILEPATH=%1
SET NB_FILELOC=%2
SET CONTAINER=%3
SET DOCKER_CMD=/bin/bash pyspark

SET DOCKER_RUN=docker run -d --env AWS_ACCESS_KEY_ID='%AWS_ACCESS_KEY_ID%' --env AWS_SECRET_ACCESS_KEY='%AWS_SECRET_ACCESS_KEY%' --env AWS_SESSION_TOKEN='%AWS_SESSION_TOKEN%' -v %CRED_FILEPATH%:/home/glue/.aws -v %NB_FILELOC%:/home/glue/notebook -p 8000:8000 --rm --name jupyter_notebook %CONTAINER% '%DOCKER_CMD%'

%DOCKER_RUN%
