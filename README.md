# Vault Secrets Management

This project leverages **HashiCorp Vault** to:

- **Dynamically manage PostgreSQL credentials**:  
  Vault automatically generates and manages time-bound database credentials.

- **Generate one-time passwords (OTP) for SSH login**:  
  Vault issues OTPs for secure SSH access.

- **Sign public keys for SSH login**:  
  Vault signs SSH public keys, enabling certificate-based authentication for secure SSH logins without the need for distributing public SSH keys across environments.

The project includes Docker configurations for both the PostgreSQL and SSH services, along with Vault integration to securely issue and manage credentials for these services.

## Getting Started

## Prerequisites
Make sure you have the following installed:
- Docker
- Docker Compose
- Vault CLI

## Setting Up the Environment
```
git clone https://github.com/dawood9598/vault-secrets-management
cd vault-secrets-management
docker-compose up -d --build
```
To set up Vault, run the initialization script:
```
cd vault
sh setup_vault.sh
```

This script performs the following steps:
1. Initialize Vault and generate unseal keys and root token, storing them in init.file.
2. Unseal Vault using the generated unseal keys.
3. Log into Vault with the root token.
4. Enable the SSH secrets engine and configure One-Time Password (OTP) SSH authentication.
5. Write SSH policies to allow OTP-based SSH login.
6. Create a Vault token for accessing SSH credentials.
7. Enable the database secrets engine for Postgres.
8. Configure Vault to manage Postgres with a readonly role.
9. Configure the SSH secrets engine to sign public SSH key

# Creating new vault admin user
```
vault auth enable userpass
vault write auth/userpass/users/vault password=vault policies=admins
```

## Generating Dynamic Posgres Credentials

To generate a username and password for the Postgres database, run:
```
vault read database/creds/readonly
```

## Generating OTP for SSH

To generate a One-Time Password (OTP) for SSH, use:
```
vault write ssh/creds/otp_key_role ip=<IP of ssh server container>
```

## SSH Key Signing with Vault

By signing clients’ SSH keys, Vault facilitates secure and automated SSH access without the need for distributing public SSH keys across environments.

#### 1. Generate an RSA SSH Key Pair
```
ssh-keygen -t rsa -b 2048 -f vault-test
```

#### 2. Sign the public SSH key using Vault's SSH client signer.
```
vault write -field=signed_key ssh-client-signer/sign/ssh-user-cert-signer public_key=@vault-test.pub valid_principals=root > signed-cert.pub
```
#### 3. Fetch the public key from Vault's SSH client signer and store it in SSH server. This public key will be used by the SSH server to verify the authenticity of SSH certificates signed by Vault.
```
curl -o /etc/ssh/trusted-user-ca-keys.pem http://vault:8200/v1/ssh-client-signer/public_key
```

#### 3. Use the signed certificate to authenticate as the root user on the target server
```
ssh -i signed-cert.pub -i vault-test root@localhost -p 3021
```

