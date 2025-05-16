# Import Linux base image (pinned for stability)
FROM ubuntu:24.04

# -------------------------
# Build-time arguments
# -------------------------
# Version of the GitHub Actions runner to install
ARG GITHUB_ACTION_RUNNER_VERSION=2.324.0
# SHA-256 checksum of the runner tarball (update when bumping version)
ARG GITHUB_ACTION_RUNNER_HASH=e8e24a3477da17040b4d6fa6d34c6ecb9a2879e800aa532518ec21e49e21d7b4
# GitHub repository URL to register the runner (e.g., https://github.com/owner/repo)
ARG GITHUB_REPOSITORY_URL=https://github.com/owner/repo
# Token used to register the runner with the GitHub repository
ARG GITHUB_RUNNER_TOKEN=00000000000000000000000000000
# Disable interactive prompts during package installs
ARG DEBIAN_FRONTEND=noninteractive

# -------------------------
# Non-root user setup
# -------------------------
# Create a dedicated 'runner' user (no password, home directory at /home/runner)
RUN useradd --create-home --shell /bin/bash runner

# -------------------------
# Install dependencies
# -------------------------
# Install essential packages and clean up APT cache
RUN apt-get update \
  && apt-get install -y \
       coreutils \
       curl \
       ca-certificates \
       gnupg \
       git \
       jq \
       build-essential \
       libssl-dev \
       libffi-dev \
       libicu-dev \
       python3 \
       python3-venv \
       python3-dev \
       python3-pip \
  && rm -rf /var/lib/apt/lists/*

# -------------------------
# Working directory
# -------------------------
# Prepare runner directory and set ownership
RUN mkdir -p /home/runner/actions-runner \
  && chown -R runner:runner /home/runner/actions-runner
WORKDIR /home/runner/actions-runner

# -------------------------
# Download & verify runner
# -------------------------
# Download, verify checksum, extract, and clean up
RUN curl -fsSL -o actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz \
       https://github.com/actions/runner/releases/download/v${GITHUB_ACTION_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz \
  && echo "${GITHUB_ACTION_RUNNER_HASH}  actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz" | sha256sum -c - \
  && tar xzf actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz \
  && rm actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz

# -------------------------
# Switch to non-root user
# -------------------------
USER runner

# -------------------------
# Runtime configuration & launch
# -------------------------
# Preconfigure the runner at build time
RUN ./config.sh --unattended --url ${GITHUB_REPOSITORY_URL} --token ${GITHUB_RUNNER_TOKEN}

# Use ENTRYPOINT to start the runner when the container runs
ENTRYPOINT ["./run.sh"]
