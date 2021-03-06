FROM amazoncorretto:latest
  
ENV glue_spark_url https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-1.0/spark-2.4.3-bin-hadoop2.8.tgz

ENV spark_zip spark-bin-hadoop.tgz

ENV maven_url https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-common/apache-maven-3.6.0-bin.tar.gz

ENV maven_zip apache-maven-bin.tar.gz

ENV glue_repo https://github.com/awslabs/aws-glue-libs

ENV maven_path /usr/local/share/applications/apache-maven

ENV glue_lib /usr/local/share/applications/aws-glue-libs

ENV SPARK_HOME /usr/local/share/applications/spark-home

ENV SPARK_CONF_DIR /usr/local/share/applications/aws-glue-libs/conf

ENV GLUE_JARS_DIR $glue_lib/jars

ENV PATH $maven_path/bin:$SPARK_HOME/bin:$glue_lib/bin:$PATH

WORKDIR /usr/local/share/applications

RUN yum install -y git wget python3 tar zip pandoc which gcc python3-devel postgresql-devel \
    && pip3 install pytest boto3 numpy scipy pandas PyGreSQL scikit-learn \
    && adduser glue -d /home/glue -s /bin/bash -m \
    && chown -R glue:glue /home/glue \
    && wget $maven_url -O $maven_zip \
    && mkdir -p $maven_path && tar -xzf $maven_zip --strip-components=1 --directory $maven_path \
    && rm -f $maven_zip \
    && wget $glue_spark_url -O $spark_zip \
    && mkdir -p $SPARK_HOME && tar -xzf $spark_zip --strip-components=1 --directory $SPARK_HOME \
    && rm -f $spark_zip \
    && git clone $glue_repo \
    && cd aws-glue-libs \
    && git checkout glue-1.0 \
    && cd $glue_lib/bin \
    && sed -e '/rm \$SPARK/ s/^rm*/rm -f/' -i glue-setup.sh \
    && sh glue-setup.sh \
    && sed -e '/mvn/ s/^#*/#/' -i glue-setup.sh \
    && rm -rf $glue_lib/jarsv1/netty-all-4.0.23.Final.jar \
    && cp $SPARK_HOME/jars/netty-all-4.1.17.Final.jar $glue_lib/jarsv1/ \
    && chown -R glue:glue /usr/local/share/applications \
    && chown -R glue:glue /usr/local/lib \
    && chown -R glue:glue /usr/local/bin \
    && chown -R glue:glue /usr/local/share
 
 USER glue

ENV PYSPARK_DRIVER_PYTHON jupyter

ENV PYSPARK_DRIVER_PYTHON_OPTS notebook

ENV PYSPARK_PYTHON python3

ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip:$glue_lib/PyGlue.zip:$PYTHONPATH

ENV PATH /home/glue/.local/bin:/home/glue/bin:$PATH

RUN pip3 install jupyter --user \
    && pip3 install git+https://github.com/sat28/githubcommit.git --user \
    && pip3 install requests --user \
    && pip3 install pytest --user \
    && pip3 install awscli --upgrade --user \
    && jupyter serverextension enable --py githubcommit --user \
    && jupyter nbextension install --py githubcommit --user \
    && jupyter nbextension enable --py githubcommit --user \
    && jupyter notebook --generate-config \
    && mkdir -p /home/glue/notebook \
    && mkdir -p /home/glue/.local/share/jupyter/kernels/gluepyspark \
    && echo "c.NotebookApp.allow_remote_access = True" >> /home/glue/.jupyter/jupyter_notebook_config.py \
    && echo "c.NotebookApp.port = 8000" >> /home/glue/.jupyter/jupyter_notebook_config.py \
    && echo "c.NotebookApp.ip = '*'" >> /home/glue/.jupyter/jupyter_notebook_config.py \
    && echo $'#!/bin/bash\n\npyspark' >> "$HOME/.local/bin/start_notebook" \
    && chmod +x "$HOME/.local/bin/start_notebook"

WORKDIR /home/glue/notebook

COPY --chown=glue:glue kernels/gluepyspark/kernel.json /home/glue/.local/share/jupyter/kernels/gluepyspark/

ENTRYPOINT [ "start_notebook" ]
