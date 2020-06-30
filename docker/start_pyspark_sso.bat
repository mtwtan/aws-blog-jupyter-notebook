@echo off
SETLOCAL EnableDelayedExpansion

SET /A ARGS_COUNT=0    
FOR %%A in (%*) DO SET /A ARGS_COUNT+=1    

echo %ARGS_COUNT%
IF %ARGS_COUNT% LSS 2 (
    echo "Please provide 2 parameters -- notebook directory (ex: C:\Users\<user>\notebook) and container name"
    EXIT /B
)


SET NB_FILELOC=%1
SET CONTAINER=%2
SET DOCKER_CMD=/bin/bash pyspark

SET DOCKER_RUN=docker run -d --env AWS_ACCESS_KEY_ID='%AWS_ACCESS_KEY_ID%' --env AWS_SECRET_ACCESS_KEY='%AWS_SECRET_ACCESS_KEY%' --env AWS_SESSION_TOKEN='%AWS_SESSION_TOKEN%' -v %NB_FILELOC%:/home/glue/notebook -p 8000:8000 --rm --name jupyter_notebook %CONTAINER% '%DOCKER_CMD%'

%DOCKER_RUN%
