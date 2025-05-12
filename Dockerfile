FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# Define URLs as environment variables
ARG PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc
ARG HL_VISOR_URL=https://binaries.hyperliquid.xyz/Mainnet/hl-visor
ARG HL_VISOR_ASC_URL=https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME
WORKDIR /home/$USERNAME

# Configure chain to testnet
RUN echo '{"chain": "Mainnet"}' > /home/$USERNAME/visor.json
#RUN echo "operator_name,root_ips\nASXN,20.188.6.225\nASXN,74.226.182.22\nB-Harvest,57.182.103.24\nB-Harvest,3.115.170.40\nNansen,46.105.222.166\nNansen,91.134.41.52" > /home/$USERNAME/override_gossip_config.json
RUN echo '{ "root_node_ips": [{"Ip": "20.188.6.225"}, {"Ip": "74.226.182.22"}, {"Ip": "57.182.103.24"}, {"Ip": "3.115.170.40"}, {"Ip": "46.105.222.166"}, {"Ip": "91.134.41.52"}], "try_new_peers": true, "chain": "Mainnet" }' > ~/override_gossip_config.json

# Import GPG public key
RUN curl -o /home/$USERNAME/pub_key.asc $PUB_KEY_URL \
    && gpg --import /home/$USERNAME/pub_key.asc

# Download and verify hl-visor binary
RUN curl -o /home/$USERNAME/hl-visor $HL_VISOR_URL \
    && curl -o /home/$USERNAME/hl-visor.asc $HL_VISOR_ASC_URL \
    && gpg --verify /home/$USERNAME/hl-visor.asc /home/$USERNAME/hl-visor \
    && chmod +x /home/$USERNAME/hl-visor

# Expose gossip ports
EXPOSE 4000-4010

# Run a non-validating node
ENTRYPOINT ["/home/hluser/hl-visor", "run-non-validator", "--replica-cmds-style", "recent-actions", "--serve-eth-rpc"]