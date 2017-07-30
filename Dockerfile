FROM ubuntu:16.04


# File Author / Maintainer
MAINTAINER  Jeff Milton

#############################################################################################
# tomcat installation
#############################################################################################
RUN apt-get update

# Install Latex
RUN apt-get install --yes build-essential python2.7-dev python-numpy python-matplotlib python-pip


# Set home directory
ENV HOME /images
WORKDIR /images


RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
        apt-get update && \
        apt-get -y upgrade && \
        apt-get install -y build-essential software-properties-common && \
        apt-get install -y byobu curl git htop man unzip vim wget && \
        apt-get install -y cmake flex bison python-numpy python-dev sqlite3 libsqlite3-dev libboost-dev libboost-system-dev libboost-thread-dev libboost-serialization-dev libboost-python-dev libboost-regex-dev && \
	apt-get install -y maven && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*
# add the rdkit requirements -- a bit redundant but I want to keep rdkit separate from pysam 
ADD requirements.txt /requirements.txt
COPY requirements.txt $HOME/requirements.txt
RUN pip install -r /requirements.txt
RUN pip install awscli


RUN pip install virtualenv
RUN pip install virtualenvwrapper
RUN export WORKON_HOME=~/Envs
RUN echo source /usr/local/bin/virtualenvwrapper.sh

#############################################################################################
#  Install a directory 
#############################################################################################



#############################################################################################
# Install Java 8.
#############################################################################################
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#############################################################################################
# configure tomcat installation
#############################################################################################
RUN echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> /etc/default/tomcat7


#############################################################################################
#  Install AWS configuration 
#############################################################################################
RUN mkdir .aws
COPY resources/awsconfig/credentials .aws


##############################################################################################
#  set ssh for pulling from bitbucket and then get the the oligo search tool and others. 
##############################################################################################
RUN mkdir /root/.ssh
ADD resources/bitbucket.keys/ir_rsa-bitbucket /root/.ssh/ir_rsa-bitbucket
ADD resources/github.keys/ir_rsa-github /root/.ssh/ir_rsa-github
ADD resources/ssh/config /root/.ssh/config
RUN chmod 400 /root/.ssh/ir_rsa-github && \
	chmod 400 /root/.ssh/ir_rsa-bitbucket
##### NO LONGE NEEDED (BELOW)
#RUN eval "$(ssh-agent)" && ssh-agent -s && \
#        chmod 600 /root/.ssh/id_rsa && \
#        ssh-add /root/.ssh/id_rsa



# Create known_hosts
RUN touch /root/.ssh/known_hosts
# Remove host checking
RUN cp -r /root/.ssh $HOME/



RUN git config --global user.email "jeffmilto@gmail.com" && \
  git config --global user.name "Jeff Milton"

RUN ssh-keyscan -H github.com > /etc/ssh/ssh_known_hosts
RUN git clone git@github.com:gwas/aws-lim-kit.git


ENV PYTHONPATH $PYTHONPATH:$HOME/
#ENV DJANGO_SETTINGS_MODULE djp.settings


#now we need to setup the virtual environment 
RUN virtualenv windnsea 
RUN echo source ./windnsea/bin/activate >> ~/.bashrc
RUN echo pip install -r /requirements.txt >> ~/.bashrc
# install the gihub django project 











EXPOSE 80 8000 8888 27017 28017 4200


#ENTRYPOINT ["sh", "apache-tomcat-7.0.73/start_tomcat.sh"]


