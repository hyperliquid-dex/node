FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

# Copy initialization script
COPY init.sh /home/$USERNAME/
RUN chmod +x /home/$USERNAME/init.sh \
    && chown $USERNAME:$USERNAME /home/$USERNAME/init.sh

USER $USERNAME
WORKDIR /home/$USERNAME

# Expose ports
EXPOSE 4000-4010 3001