# Usig the Alpine GNU image as the parent image 
FROM frolvlad/alpine-glibc:latest

# Setting the working directory to /app
WORKDIR /app

# Copy content in my directory into the container at /app 
COPY . /app

# Install the bash shell and curl command in Alpine Linux 
RUN apk update && apk upgrade && apk add bash curl

# Install OpenShift CLI
RUN curl -kLso /tmp/oc-client.tar.gz https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz \
    && tar xvfz /tmp/oc-client.tar.gz --strip-components=1 -C /bin \
    && rm /tmp/oc-client.tar.gz
