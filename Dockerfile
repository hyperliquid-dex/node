FROM ubuntu:24.04

# configure chain to testnet
RUN echo '{"chain": "Testnet"}' > ~/visor.json

# save the public list of peers to connect to
ADD https://binaries.hyperliquid.xyz/Testnet/initial_peers.json ~/initial_peers.json

# temporary configuration file (will not be required in future update)
RUN curl https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json > ~/non_validator_config.json

# add the binary
RUN curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor

# gossip ports
EXPOSE 9000
EXPOSE 8000

ENTRYPOINT ["~/hl-visor"]