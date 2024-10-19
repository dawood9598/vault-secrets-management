#!/bin/bash

# Set the Vault server address for the session. This is where the Vault API will be accessible.
export VAULT_ADDR=http://0.0.0.0:8200

# Initialize Vault and generate unseal keys and a root token.
vault operator init > init.file

# Unseal the Vault using the first three unseal keys generated during initialization.
vault operator unseal $(grep 'Unseal Key 1' init.file | awk '{print $NF}')
vault operator unseal $(grep 'Unseal Key 2' init.file | awk '{print $NF}')
vault operator unseal $(grep 'Unseal Key 3' init.file | awk '{print $NF}')

# Retrieve the root token from the initialization output file and export it as an environment variable.
# This token allows the script to perform operations with root privileges.
VAULT_TOKEN=$(grep 'Root Token' init.file | awk '{print $NF}')
export VAULT_TOKEN

# Enable the SSH secrets engine in Vault. This allows Vault to manage SSH credentials.
vault secrets enable ssh

# Configure an SSH role named 'otp_key_role' that generates one-time passwords (OTPs) for SSH access.
# - key_type=otp: Indicates that the key type is OTP.
# - default_user=vault: Specifies the default username for SSH access.
# - cidr_list=0.0.0.0/0: Allows access from all IP addresses (modify this in production).
vault write ssh/roles/otp_key_role key_type=otp default_user=vault cidr_list=0.0.0.0/0

# Enable the Database secrets engine in Vault, allowing it to manage database credentials.
vault secrets enable database

# Configure the PostgreSQL Database secrets engine.
# This sets up the connection details for Vault to access the PostgreSQL database.
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@database:5432/vault-db?sslmode=disable" \
  allowed_roles=readonly \
  username="root" \
  password="rootpassword"

# Create a role named 'readonly' in the database secrets engine.
# This role defines the creation statements for user credentials.
vault write database/roles/readonly \
    db_name="postgresql" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"  

# This allows Vault to manage SSH certificates and sign client SSH certificates.
# The path "ssh-client-signer" can be customized as needed.
vault secrets enable -path=ssh-client-signer ssh

# Configure the SSH secrets engine to generate a new signing key for the CA (Certificate Authority).
# This key will be used by Vault to sign SSH client certificates.
# The key will be stored in Vault and used for authenticating SSH client sessions.
vault write ssh-client-signer/config/ca generate_signing_key=true

#The ssh-client-signer endpoint is used to sign SSH client certificates via Vault’s SSH secrets engine.
#allowed_extensions allows the certificate to grant permission for interactive shell access and port forwarding
vault write ssh-client-signer/roles/ssh-user-cert-signer -<<"EOH"
{
  "algorithm_signer": "rsa-sha2-256",
  "allow_user_certificates": true,
  "allowed_users": "*",
  "allowed_extensions": "permit-pty,permit-port-forwarding", 
  "default_extensions": {
    "permit-pty": ""
  },
  "key_type": "ca",
  "default_user": "ubuntu",
  "ttl": "30m0s"
}
EOH