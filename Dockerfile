FROM registry.access.redhat.com/rhel7/rhel

MAINTAINER chumakov_ja@mail.ru

LABEL "ProductID"="447aefb5fd1342d5b893f3934dfded73" \
      "ProductName"="IBM Integration Bus" \
      "ProductVersion"="10.0.0.23"

# Create user to run as
RUN groupadd -og 0 mqbrkrs && \
    useradd --create-home --home-dir /home/mqm -u 601 -G mqbrkrs mqm && mkdir /opt/ibm 
    
# Install IIB V10 Developer edition
RUN curl ftp://192.168.1.1/oracle_install.tar.gz \
    | tar zx --directory /tmp && \
    /opt/ibm/iib-10.0.0.23/iib make registry global accept license silently

RUN mkdir /opt/ibm && \
    curl ftp://192.168.1.1/10.0.0.23-IIB-LINUX64-DEVELOPER.tar.gz \
    | tar zx --exclude iib-10.0.0.16/tools --directory /opt/ibm && \
    /opt/ibm/iib-10.0.0.23/iib make registry global accept license silently


# Configure system
COPY kernel_settings.sh /tmp/
RUN chmod +x /tmp/kernel_settings.sh;sync && \
    /tmp/kernel_settings.sh


# Copy in script files
COPY iib_manage.sh /usr/local/bin/
COPY iib-license-check.sh /usr/local/bin/
COPY iib_env.sh /usr/local/bin/
RUN chmod +rx /usr/local/bin/*.sh

# Set BASH_ENV to source mqsiprofile when using docker exec bash -c
ENV BASH_ENV=/usr/local/bin/iib_env.sh
ENV MQSI_MQTT_LOCAL_HOSTNAME=127.0.0.1

# Expose default admin port and http port
EXPOSE 4414 7800
# Because the user ID of the container is generated dynamically, it will not have an associated entry in /etc/passwd. This can cause problems for applications that expect to be able to look up their user ID. One way to address this problem is to dynamically create a passwd file entry with the container’s user ID as part of the image’s start script. This is what a Dockerfile might include:
RUN chmod g=u /etc/passwd

# Set entrypoint to run management script
ENTRYPOINT ["iib_manage.sh"]

USER 1001
