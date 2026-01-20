FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# Define URLs as environment variables
ARG PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc
ARG HL_VISOR_URL=https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor
ARG HL_VISOR_ASC_URL=https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME
WORKDIR /home/$USERNAME

# Configure chain to testnet
RUN echo '{"chain": "Testnet"}' > /home/$USERNAME/visor.json

# Import GPG public key
RUN curl -o /home/$USERNAME/pub_key.asc $PUB_KEY_URL \
    && gpg --import /home/$USERNAME/pub_key.asc

# Download and verify hl-visor binary
RUN curl -o /home/$USERNAME/hl-visor $HL_VISOR_URL \
    && curl -o /home/$USERNAME/hl-visor.asc $HL_VISOR_ASC_URL \
    && gpg --verify /home/$USERNAME/hl-visor.asc /home/$USERNAME/hl-visor \
    && chmod +x /home/$USERNAME/hl-visor

# Expose rpc port
EXPOSE 3001
# Expose gossip ports
EXPOSE 4000-4010

# Run a non-validating node
ENTRYPOINT ["/home/hluser/hl-visor", "run-non-validator", "--replica-cmds-style", "recent-actions"]

# Optional: Run a non-validating node with EVM RPC enabled (if using, comment out the above line and uncomment this one)
# ENTRYPOINT ["/home/hluser/hl-visor", "run-non-validator", "--serve-eth-rpc", "--replica-cmds-style", "recent-actions"]