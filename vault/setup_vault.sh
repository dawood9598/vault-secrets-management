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
  plugin_name=postgresql-database-plugin \  # Use the PostgreSQL database plugin.
  connection_url="postgresql://{{username}}:{{password}}@database:5432/vault-db?sslmode=disable" \  # Connection string with placeholders for username and password.
  allowed_roles=readonly \  # Roles that are allowed to use this connection.
  username="root" \  # Database username for authentication.
  password="rootpassword"  # Database password for authentication.

# Create a role named 'readonly' in the database secrets engine.
# This role defines the creation statements for user credentials.
vault write database/roles/readonly \
    db_name="postgresql" \  # Specify the database name.
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \  # SQL statements to create a new role and grant SELECT permissions.
    default_ttl="1h" \  # Set the default time-to-live (TTL) for the credentials to 1 hour.
    max_ttl="24h"  # Set the maximum TTL for the credentials to 24 hours.

