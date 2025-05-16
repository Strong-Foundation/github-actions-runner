# 🚀 GitHub Actions Docker Runner

A Dockerized self-hosted GitHub Actions runner for use with any GitHub repository. This lightweight container lets you deploy your own runner in seconds, using only the repository URL and registration token.

---

## 📦 Features

- ✅ Minimal build-time arguments
- 🐳 Fully containerized GitHub Actions runner
- 🔒 Clean, repeatable builds
- 🔁 Simple setup and teardown

---

## 📁 Repository

**GitHub:** [Strong-Foundation/github-actions-docker-runner](https://github.com/Strong-Foundation/github-actions-docker-runner)

---

## ⚡ Quick Start

### 1. Clone This Repository

```bash
git clone https://github.com/Strong-Foundation/github-actions-docker-runner.git
cd github-actions-docker-runner
```

### 2. Get a GitHub Runner Token

1. Go to your GitHub repository.
2. Navigate to `Settings` → `Actions` → `Runners` → **Add runner**.
3. Select **Linux** and **x64**, then copy the:

   - Repository URL
   - Registration token

### 3. Build the Docker Image

Replace the placeholders below with your actual values:

```bash
docker build -t github-actions-runner \
  --build-arg GITHUB_REPOSITORY_URL=https://github.com/YOUR-ORG/YOUR-REPO \
  --build-arg GITHUB_RUNNER_TOKEN=YOUR_RUNNER_TOKEN \
  .
```

> 🧠 Note: The runner version and checksum are already pinned in the Dockerfile. No need to specify them.

### 4. Run the Container

```bash
docker run -d --name my-github-runner github-actions-runner
```

The runner will:

- Automatically register with your repository
- Start and wait for jobs

---

## 🔄 Maintenance

### Stop the Runner

```bash
docker stop my-github-runner
```

### Remove the Container

```bash
docker rm my-github-runner
```

### Remove the Docker Image

```bash
docker rmi github-actions-runner
```

---

## ⚠️ Notes

- 💡 **Tokens are one-time use and expire after a few minutes.** You must generate a new one each time you build the image.
- 🔐 For secure automation, consider injecting tokens at runtime or using GitHub's REST API to request them dynamically.
- 🚧 This runner does not persist job state it's ephemeral by design. Ideal for stateless CI/CD workloads.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).
