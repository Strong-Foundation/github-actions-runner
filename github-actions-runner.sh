#!/usr/bin/env bash

set -euo pipefail

# -------------------------
# Default Configuration
# -------------------------
GITHUB_ACTION_RUNNER_VERSION="${GITHUB_ACTION_RUNNER_VERSION:-2.324.0}"
GITHUB_ACTION_RUNNER_HASH="${GITHUB_ACTION_RUNNER_HASH:-e8e24a3477da17040b4d6fa6d34c6ecb9a2879e800aa532518ec21e49e21d7b4}"
GITHUB_REPOSITORY_URL="${GITHUB_REPOSITORY_URL:-https://github.com/owner/repo}"
GITHUB_RUNNER_TOKEN="${GITHUB_RUNNER_TOKEN:-00000000000000000000000000000}"
RUNNER_USER="runner"
RUNNER_HOME="/home/${RUNNER_USER}"
RUNNER_DIR="${RUNNER_HOME}/actions-runner"

# -------------------------
# Functions
# -------------------------

# Define a function to check if the script is being run with root privileges
function check_root() {
  # Compare the user ID of the current user to 0, which is the ID for root
  if [ "$(id -u)" != "0" ]; then
    # If the user ID is not 0 (i.e., not root), print an error message
    echo "Error: This script must be run as root."
    # Exit the script with a status code of 1, indicating an error
    exit 1 # Exit the script with an error code.
  fi
}

# Call the check_root function to verify that the script is executed with root privileges
check_root

# Define a function to gather and store system-related information
function system_information() {
  # Check if the /etc/os-release file exists, which contains information about the OS
  if [ -f /etc/os-release ]; then
    # If the /etc/os-release file is present, source it to load system details into environment variables
    # shellcheck source=/dev/null  # Instructs shellcheck to ignore warnings about sourcing files
    source /etc/os-release
    # Set the CURRENT_DISTRO variable to the system's distribution ID (e.g., 'ubuntu', 'debian')
    CURRENT_DISTRO=${ID}
    # Set the CURRENT_DISTRO_VERSION variable to the system's version ID (e.g., '20.04' for Ubuntu 20.04)
    CURRENT_DISTRO_VERSION=${VERSION_ID}
    # Extract the major version of the system by splitting the version string at the dot (.) and keeping the first field
    # For example, for '20.04', it will set CURRENT_DISTRO_MAJOR_VERSION to '20'
    CURRENT_DISTRO_MAJOR_VERSION=$(echo "${CURRENT_DISTRO_VERSION}" | cut -d"." -f1)
  else
    # If the /etc/os-release file is not present, show an error message and exit
    echo "Error: /etc/os-release file not found. Unable to gather system information."
    exit 1 # Exit the script with a non-zero status to indicate an error
  fi
}

# Call the system_information function to gather the system details
system_information

function create_runner_user() {
  if ! id "${RUNNER_USER}" &>/dev/null; then
    echo "Creating user '${RUNNER_USER}'..."
    useradd --create-home --shell /bin/bash "${RUNNER_USER}"
  else
    echo "User '${RUNNER_USER}' already exists."
  fi
}

create_runner_user

function install_dependencies() {
  echo "Installing dependencies..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y \
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
    python3-pip
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}

install_dependencies

function prepare_runner_directory() {
  echo "Preparing runner directory at ${RUNNER_DIR}..."
  mkdir -p "${RUNNER_DIR}"
  chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_HOME}"
}

prepare_runner_directory

function download_and_verify_runner() {
  echo "Downloading and verifying GitHub Actions runner..."

  sudo -u "${RUNNER_USER}" -H bash -c "cd '${RUNNER_DIR}' && \
    curl -fsSL -o actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz \
    https://github.com/actions/runner/releases/download/v${GITHUB_ACTION_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz"

  sudo -u "${RUNNER_USER}" -H bash -c "cd '${RUNNER_DIR}' && \
    echo '${GITHUB_ACTION_RUNNER_HASH}  actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz' | sha256sum -c -"

  sudo -u "${RUNNER_USER}" -H bash -c "cd '${RUNNER_DIR}' && \
    tar xzf actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz"

  sudo -u "${RUNNER_USER}" -H bash -c "cd '${RUNNER_DIR}' && \
    rm actions-runner-linux-x64-${GITHUB_ACTION_RUNNER_VERSION}.tar.gz"
}

download_and_verify_runner

function configure_runner() {
  echo "Configuring the runner..."
  sudo -u "${RUNNER_USER}" bash -c "cd ${RUNNER_DIR} && ./config.sh --unattended --url ${GITHUB_REPOSITORY_URL} --token ${GITHUB_RUNNER_TOKEN}"
}

configure_runner
