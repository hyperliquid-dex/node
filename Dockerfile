FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# create custom user, install dependencies, create data directory
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install curl -y \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME

WORKDIR /home/$USERNAME

# configure chain to testnet
RUN echo '{"chain": "Testnet"}' > /home/$USERNAME/visor.json

# save the public list of peers to connect to
ADD --chown=$USER_UID:$USER_GID https://binaries.hyperliquid.xyz/Testnet/initial_peers.json /home/$USERNAME/initial_peers.json

# temporary configuration file (will not be required in future update)
ADD --chown=$USER_UID:$USER_GID https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json /home/$USERNAME/non_validator_config.json

# add the binary
ADD --chown=$USER_UID:$USER_GID --chmod=700 https://binaries.hyperliquid.xyz/Testnet/hl-visor /home/$USERNAME/hl-visor

# gossip ports
EXPOSE 9000
EXPOSE 8000

ENTRYPOINT $HOME/hl-visor
