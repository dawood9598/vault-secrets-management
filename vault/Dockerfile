FROM vault:1.13.3

# Copy the Vault configuration
COPY config/vault.json /vault/config/vault.json


# Start Vault server
CMD ["sh", "-c", "vault server -config=/vault/config/vault.json"]