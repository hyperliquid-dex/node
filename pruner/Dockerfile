FROM debian:12.6-slim

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# create custom user, install dependencies, create data directory
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install curl cron procps -y \
    && mkdir -p /home/$USERNAME/hl/data && mkdir -p /home/$USERNAME/scripts && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

# Add our scripts
COPY scripts/ /home/$USERNAME/scripts/
# Add cron file
COPY cron/ /etc/

# Give execution rights on the cron jobs
RUN chmod 0644 /etc/cron.d/* && \
    chmod +x /home/$USERNAME/scripts/* && chown -R $USERNAME:$USERNAME /home/$USERNAME/scripts

# Start cron service directly
CMD ["bash", "-c", "crontab /etc/cron.d/prune && /usr/sbin/cron -f -L 15"]
