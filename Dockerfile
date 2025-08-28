FROM --platform=linux/amd64 ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl tree gnupg qemu-user-static binfmt-support sudo python3 python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl \
    && chmod 755 /home/$USERNAME/hl/data \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install Poetry for hluser
USER $USERNAME
RUN curl -sSL --retry 3 --retry-delay 2 https://install.python-poetry.org | python3 - \
    && echo "export PATH=\"/home/$USERNAME/.local/bin:\$PATH\"" >> /home/$USERNAME/.bashrc \
    && /home/$USERNAME/.local/share/pypoetry/venv/bin/poetry --version

# Switch back to root for remaining operations
USER root

# Copy initialization script
COPY script/init.sh /home/$USERNAME/
RUN chmod +x /home/$USERNAME/init.sh \
    && chown $USERNAME:$USERNAME /home/$USERNAME/init.sh

# Copy startup script
COPY script/startup.sh /home/$USERNAME/
RUN chmod +x /home/$USERNAME/startup.sh \
    && chown $USERNAME:$USERNAME /home/$USERNAME/startup.sh

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Set USERNAME environment variable
ENV USERNAME=$USERNAME

# Set PATH to include Poetry
ENV PATH="/home/$USERNAME/.local/bin:$PATH"

# Run initialization as hluser
RUN /home/$USERNAME/init.sh

CMD /home/$USERNAME/startup.sh

EXPOSE 4000-4010 3001