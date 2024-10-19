# Use the official Ubuntu image
FROM --platform=linux/amd64 ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update packages and install OpenSSH server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    apt-get install -y unzip curl && \
    mkdir /var/run/sshd && \ 
    apt-get clean

COPY sshd_config /etc/ssh/sshd_config

RUN useradd -m -s /bin/bash vault

#Add the 'vault' user to the sudo group
RUN usermod -aG sudo vault

RUN echo 'root:root' | chpasswd

# Expose port 22
EXPOSE 22

# start SSH service
CMD [/usr/sbin/sshd -D]

