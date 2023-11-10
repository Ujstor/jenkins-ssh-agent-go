# Jenkins Configuration and Pipeline Setup

This guide offers short instructions for configuring Jenkins Controller and Agents to facilitate the execution of pipeline jobs. While Jenkins can be set up locally using Docker Compose, I recommend configuring a dedicated server. Numerous tutorials are available for controller installation, and you can refer to the official [documentation](https://www.jenkins.io/doc/book/installing/linux/).

## Step 1: Retrieve Jenkins Controller Initial Admin Password

After installation, whether as a local Docker container or on a server, locate the InitialAdminPassword in `/var/jenkins_home/secrets/initialAdminPassword`.

```bash
cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy the generated password.

## Step 2: Initial Setup

- Open Jenkins in a web browser.
- Paste the initial admin password.
- Follow the on-screen instructions to complete the setup.

## Step 3: Additional Configurations

Enhance your Jenkins setup with the following steps, consulting the Jenkins documentation for clarity on any ambiguous steps.

1. **Install Necessary Plugins:**
   - Navigate to "Manage Jenkins" > "Manage Plugins" > "Available."
   - Search and install the required plugins for your pipeline jobs.

2. **Create GitHub App Webhook:**
   - In your GitHub repository, go to "Settings" > "DeveloperSettings" > "GitHubApp."
   - This step might be complex; refer to the official documentation and accompanying [video content](https://www.jenkins.io/doc/book/using/best-practices/).
   - If deploying on a local machine without a server and domain, consider using [ngrok](https://ngrok.com/) as a reverse proxy.

3. **Add GitHub and Docker Credentials:**
   - Navigate to "Manage Jenkins" > "Manage Credentials" to add credentials for GitHub, SSH Agent, and Docker (if needed).

4. **Create SSH Key in Jenkins Controller:**
   - Generate an SSH key in Jenkins for authenticating with version control systems.
   - Run `ssh-keygen -t ed25519 -f ~/.ssh/jenkins_agent_key` and grab the public key.

5. **Create SSH Agent for Your Job:**
   - Set up an SSH agent for your Jenkins job, avoiding running it on the controller for security reasons.
   - Details about configuration are in the SSHagent folder.
   - Run the following Docker command:
     ```bash
     docker run -v /var/run/docker.sock:/var/run/docker.sock -d --rm --name=agent1 -p 22:22 \
     -e "JENKINS_AGENT_SSH_PUBKEY=[your-public-key]" \
     <agent_image>
     ```
   - Follow official [docs](https://www.jenkins.io/doc/book/using/using-agents/) for configuration and pairing with the controller.

6. **Create Jenkins Multibranch Pipeline Job:**
   - The Jenkinsfile at the root of a project is a simple pipeline for generating Docker images and pushing them with tags into DockerHub.
   - The idea is to add a test stage for testing code in any branch and push the image into the repository if tests pass and the branch is the main one.
   - For other branches, the pipeline can be used for code testing.
   - More information about the pipeline is below.

7. **Deploy Your App:**
   - Once the pipeline is in place, every merge with passing tests results in a deployable image.
   - Application deployment can be achieved using Docker Compose and hosting on the cloud, self-hosting services like [Collify](https://coolify.io/), Kubernetes, etc.

## Note:
- Adjust configurations based on your specific requirements.
- Always consider security best practices, especially when handling credentials and sensitive information.
- Explore Jenkins documentation for detailed configuration options: [Jenkins Documentation](https://www.jenkins.io/doc/)

<br>

# SSH-Go-Agent

In a Jenkins environment, agents play a crucial role in distributing workload and executing jobs in parallel. This guide illustrates how to set up Jenkins agents using Docker images with SSH. The Dockerfile uses the `jenkins/ssh-agent` as the base image and installs various tools and dependencies needed for Go development, testing, and containerization. Customize the Dockerfile to include any additional dependencies or tools your project may require.

Once all dependencies are satisfied, build and push the image to DockerHub:

```bash
docker build -t <repoName>/<imageName>:<tagName> .
docker push <repoName>/<imageName>:<tagName>
```

## Generating an SSH Key Pair

To set up an SSH key pair, follow these steps:

2. Generate the SSH key pair by running the following command:

    ```bash
    ssh-keygen -t ed25519 -f ~/.ssh/jenkins_agent_key
    ```

## Creating a Jenkins SSH Credential

1. Go to your Jenkins dashboard.

2. In the main menu, click on "Manage Jenkins" and select "Manage Credentials."

3. Click on the "Add Credentials" option from the global menu.

4. Fill in the following information:

   - Kind: SSH Username with private key
   - ID: jenkins
   - Description: The Jenkins SSH key
   - Username: jenkins
   - Private Key: Select "Enter directly" and paste the content of your private key file located at `~/.ssh/jenkins_agent_key`
   - Passphrase: Fill in your passphrase used to generate the SSH key pair (leave empty if you didn't use one)

## Creating Your Docker Agent

Use the `docker-ssh-agent` image that you created and pushed into the DockerHub repo:

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -d --rm --name=agent1 -p 2222:22 \
    -e "JENKINS_AGENT_SSH_PUBKEY=[your-public-key]" \
    <repoName>/<imageName>:<tagName>
```

Replace `[your-public-key]` with your own SSH public key. You can find your public key value by running `cat ~/.ssh/jenkins_agent_key.pub` on the machine where you created it.

If your machine already has an SSH server running on port 22, consider using a different port for the Docker command, such as `-p 2222:22`.

### Registering the Agent in Jenkins

1. Go to your Jenkins dashboard.

2. Click on "Manage Jenkins" in the main menu.

3. Select "Manage Nodes and Clouds."

4. Click on "New Node" from the side menu.

5. Fill in the Node/agent name and select the type (e.g., Name: agent1, Type: Permanent Agent).

6. Fill in the following fields:

   - Remote root directory (e.g., /home/jenkins)
   - Label (e.g., agent1)
   - Usage (e.g., only build jobs with label expression)
   - Launch method (e.g., Launch agents by SSH)
     - Host (e.g., localhost or your IP address)
     - Credentials (e.g., jenkins)
     - Host Key Verification Strategy (e.g., Manually trusted key verification)
     - Change the port if needed; in my case, I need to use port 2222

<br>

# Jenkins Pipeline

The pipeline automates the process of checking out code from a GitHub repository, generating Docker image tags, building and pushing the Docker image to DockerHub, and performing environment cleanup.


## Configuration

To adapt the pipeline to your specific project, modify the following environment variables in the pipeline script:

- `GITHUB_USER`: GitHub username or organization name.
- `GITHUB_REPO`: Name of the GitHub repository.
- `DOCKER_HUB_USERNAME`: DockerHub username for image storage.
- `DOCKER_REPO_NAME`: Name of the Docker repository.
- `BRANCH`: Branch of the GitHub repository to be built and deployed.
- `VERSION_PART`: Versioning strategy (Patch, Minor, Major).
- `DOCKER_JENKINS_CREDENTIALS_ID`: Jenkins credentials ID for DockerHub login.

## Running the Pipeline

1. Create a new Jenkins job and select "Multibranch Pipeline" as the job type.

2. In the pipeline configuration add GitHub as surce.

3. Configure the necessary parameters, such as GitHub and DockerHub credentials.

4. Save the pipeline configuration.

5. Run the Jenkins job to trigger the pipeline.

## Pipeline Overview

The Jenkins Pipeline is structured into several stages:

- **Checkout Code:** Checks out code from the specified GitHub repository and branch.

- **Generate Docker Image Tag:** Automatically generates a Docker image tag based on the specified versioning strategy (Patch, Minor, Major).

- **Docker Login:** Logs into DockerHub using provided credentials for image storage.

- **Build:** Builds the Docker image from checked-out code, incorporating project changes.

- **Deploy:** Pushes the built Docker image to DockerHub for deployment.

- **Environment Cleanup:** Removes the Docker image locally for resource management.

