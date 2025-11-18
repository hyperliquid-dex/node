FROM debian:12.6-slim

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# create custom user, install dependencies, create data directory
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install curl cron procps unzip lz4 -y \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip \
    && mkdir -p /home/$USERNAME/hl/data && mkdir -p /home/$USERNAME/scripts && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

# Add our scripts
COPY scripts/ /home/$USERNAME/scripts/
# Add cron file
COPY cron/ /etc/

# Give execution rights on the cron jobs
RUN chmod 0644 /etc/cron.d/* && \
    chmod +x /home/$USERNAME/scripts/* && chown -R $USERNAME:$USERNAME /home/$USERNAME/scripts

# Start cron service directly
CMD ["bash", "-c", "cat /etc/cron.d/prune /etc/cron.d/s3_sync | crontab - && /usr/sbin/cron -f -L 15"]
