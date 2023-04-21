# Create a OCI Image for GitHub Actions Runner, based on Debian Buster Slim and then push it to GitHub Container Registry. Don't forget to label and tag it.
FROM ubuntu:lunar
# Get the token to register the runner from the GitHub Actions Runner Token Secret in GitHub Secrets and set it as an environment variable.
ENV BUILD_DATE=${BUILD_DATE}
ENV URL_ORG=${URL_ORG}
ENV TOKEN_RUNNER=${TOKEN_RUNNER}

LABEL org.opencontainers.image.title="GitHub Actions Runner" \
      org.opencontainers.image.description="GitHub Actions Runner" \
      org.opencontainers.image.vendor="SREDevOps.cl" \
      org.opencontainers.image.version="${BUILD_DATE}" \
      org.opencontainers.image.authors="Nicolás Georger <info@sredevops.cl>" \
      org.opencontainers.image.source="https://github.com/sredevopsdev/github-self-hosted-runner-k8s" \
      org.opencontainers.image.licenses="GNU General Public License v3.0" \
      org.opencontainers.image.url="ghcr.io/sredevopsdev/github-self-hosted-runner-k8s" \
      org.opencontainers.image.documentation="https://github.com/sredevopsdev/github-self-hosted-runner-k8s/"

# Set Debian Frontend to noninteractive
ENV DEBIAN_FRONTEND=noninteractive
# Install dependencies
RUN apt update && apt install --no-install-recommends -y \
    ca-certificates \
    apt-transport-https \
    curl \
    git \
    jq \
    sudo \
    tzdata \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt autoremove -y \
    && apt autoclean -y

# Create a user to run the GitHub Actions Runner and add it to the sudoers group, then set the user as the default user, using the user's home directory as the working directory.

RUN useradd -m runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R runner:runner /home/runner \
    && mkdir -p /home/runner/actions-runner \
    && chown -R runner:runner /home/runner/actions-runner \
    && chmod -R 0777 /home/runner/actions-runner 

USER runner

WORKDIR /home/runner/actions-runner

# Get the latest release tag from GitHub, so we can download the latest version of the GitHub Actions Runner using wget and the tag. 
# Download the latest runner package
# ToDo: Dynamic versioning.
# Use environment variables to set the GitHub Organization and Repository to register the runner to.

RUN curl -O -L https://github.com/actions/runner/releases/download/v2.303.0/actions-runner-linux-x64-2.303.0.tar.gz && \
    tar xzf actions-runner-linux-x64-2.303.0.tar.gz && rm -fv actions-runner-linux-x64-2.303.0.tar.gz 
    
RUN sudo ./bin/installdependencies.sh || true
RUN sudo ./config.sh --url $URL_ORG --token $TOKEN

# Set the GitHub Actions Runner Token as an environment variable. 
# Register the runner to the GitHub Organization and Repository using the GitHub Actions Runner Token.

ENTRYPOINT [ "bash", "-c", "./run.sh" ]
