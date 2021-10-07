# Usig the Alpine GNU image as the parent image 
FROM frolvlad/alpine-glibc:latest

# Install the bash shell, curl command, and python3 on Alpine Linux 
RUN apk update && apk upgrade && apk add bash curl python3

# Install OpenShift CLI
RUN curl -kLso /tmp/oc-client.tar.gz https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz \
    && tar xvfz /tmp/oc-client.tar.gz --strip-components=1 -C /bin \
    && rm /tmp/oc-client.tar.gz

# Copy the kube.config file and place in apropriate directory 
COPY kube.config /root/.kube/config

# Copy content in my directory into the container at /app 
COPY . /app

# Setting the working directory to /app
WORKDIR /app

# Run the migration script
CMD [ "/bin/bash", "execution.sh" ]