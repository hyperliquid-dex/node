FROM ubuntu:24.04

ARG USERNAME=hl
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# create custom user, install dependencies, create data directory
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install curl -y \
    && mkdir -p /home/hl/hl/data && chown -R $USERNAME:$USERNAME /home/hl/hl

USER $USERNAME

WORKDIR /home/hl

# configure chain to testnet
RUN echo '{"chain": "Testnet"}' > /home/hl/visor.json

# save the public list of peers to connect to
ADD --chown=10000:10000 https://binaries.hyperliquid.xyz/Testnet/initial_peers.json /home/hl/initial_peers.json

# temporary configuration file (will not be required in future update)
ADD --chown=10000:10000 https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json /home/hl/non_validator_config.json

# add the binary
ADD --chown=10000:10000 --chmod=700 https://binaries.hyperliquid.xyz/Testnet/hl-visor /home/hl/hl-visor

# gossip ports
EXPOSE 9000
EXPOSE 8000

ENTRYPOINT ["/home/hl/hl-visor"]