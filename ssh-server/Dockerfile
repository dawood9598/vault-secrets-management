# Use the official Ubuntu image
FROM --platform=linux/amd64 ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update packages and install OpenSSH server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    apt-get install -y unzip && \
    mkdir /var/run/sshd && \ 
    apt-get clean

COPY sshd_config /etc/ssh/sshd_config

COPY sshd /etc/pam.d/sshd

ADD config.hcl /etc/vault-ssh-helper.d/config.hcl

RUN export VAULT_ADDR=http://vault:8200 &&\
    wget https://releases.hashicorp.com/vault-ssh-helper/0.2.1/vault-ssh-helper_0.2.1_linux_amd64.zip &&\
    unzip -q vault-ssh-helper_0.2.1_linux_amd64.zip -d /usr/local/bin &&\
    chmod 0755 /usr/local/bin/vault-ssh-helper &&\
    chown root:root /usr/local/bin/vault-ssh-helper &&\
    rm vault-ssh-helper_0.2.1_linux_amd64.zip

RUN useradd -m -s /bin/bash vault

#Add the 'vault' user to the sudo group
RUN usermod -aG sudo vault

# Expose port 22
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]