# Vault Secrets Management
This project sets up a secure secrets management solution for Postgres, and an SSH server using HashiCorp Vault. It includes Docker files for each service and configuration files to manage Vault’s interaction with these services.

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
sh setup_vault.sh
```

This script performs the following steps:
1. Initialize Vault and generate unseal keys and root token, storing them in /vault/init.file.
2. Unseal Vault using the generated unseal keys.
3. Log into Vault with the root token.
4. Enable the SSH secrets engine and configure One-Time Password (OTP) SSH authentication.
5. Write SSH policies to allow OTP-based SSH login.
6. Create a Vault token for accessing SSH credentials.
7. Enable the database secrets engine for Postgres.
8. Configure Vault to manage Postgres with a readonly role.

## Generating Credentials

To generate a username and password for the Postgres database, run:
```
vault read database/creds/readonly
```

To generate a One-Time Password (OTP) for SSH, use:
```
vault write ssh/creds/otp_key_role ip=<IP of ssh server container>
```

