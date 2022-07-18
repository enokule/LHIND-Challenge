FROM jenkins/inbound-agent:4.11.2-4
USER root
RUN apt-get update
RUN apt-get install apt-transport-https ca-certificates curl software-properties-common gnupg -y
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
RUN apt-get update
RUN apt-cache policy docker-ce
RUN apt-get install docker-ce -y
CMD ["sh","start.sh"]
RUN usermod -aG docker jenkins
USER jenkins
