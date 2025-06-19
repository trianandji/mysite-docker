pipeline {
    agent any // Or a specific agent if you have Jenkins agents configured

    environment {
        // Essential for Docker commands to interact with Minikube's daemon
        DOCKER_HOST = sh(returnStdout: true, script: 'minikube docker-env --shell bash | grep DOCKER_HOST | cut -d "=" -f 2 | tr -d \'\n\'')
        DOCKER_CERT_PATH = sh(returnStdout: true, script: 'minikube docker-env --shell bash | grep DOCKER_CERT_PATH | cut -d "=" -f 2 | tr -d \'\n\'')
        DOCKER_TLS_VERIFY = sh(returnStdout: true, script: 'minikube docker-env --shell bash | grep DOCKER_TLS_VERIFY | cut -d "=" -f 2 | tr -d \'\n\'')
        // Define your Docker image name
        IMAGE_NAME = "trianandji/drupal-app" // Match this with your drupal-deployment.yaml
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/trianandji/mysite-docker.git'
                // No credentials needed for public repo
            }
        }

        stage('Build and Tag Docker Image') {
            steps {
                script {
                    // Use Jenkins build number as the image tag for versioning
                    def buildImageTag = "${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    def latestImageTag = "${IMAGE_NAME}:latest"

                    // Ensure Docker environment variables are loaded for this stage
                    withEnv(["DOCKER_HOST=${DOCKER_HOST}", "DOCKER_CERT_PATH=${DOCKER_CERT_PATH}", "DOCKER_TLS_VERIFY=${DOCKER_TLS_VERIFY}"]) {
                        sh "docker build -t ${buildImageTag} ." // Build with unique tag
                        sh "docker tag ${buildImageTag} ${latestImageTag}" // Also tag as latest
                        echo "Built and tagged image: ${buildImageTag} and ${latestImageTag}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Dynamically update the image in the Kubernetes YAML
                    // We're updating 'latest' tag directly. When Kubernetes sees the image contents change
                    // for 'latest', it triggers a rollout.
                    // For macOS sed, use -i '' for in-place editing without a backup file.
                    sh "sed -i '' 's|${IMAGE_NAME}:latest|${IMAGE_NAME}:${env.BUILD_NUMBER}|g' drupal-deployment.yaml"
                    echo "Updated drupal-deployment.yaml to use image ${IMAGE_NAME}:${env.BUILD_NUMBER}"

                    // Apply the Kubernetes deployment and service
                    sh "kubectl apply -f drupal-deployment.yaml"
                    echo "Deployment applied to Minikube."

                    // Wait for the deployment to finish its rollout
                    sh "kubectl rollout status deployment/drupal-deployment --timeout=300s"
                    echo "Deployment rollout complete."
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
            // Optional: Clean up old Docker images in Minikube's daemon
            script {
                withEnv(["DOCKER_HOST=${DOCKER_HOST}", "DOCKER_CERT_PATH=${DOCKER_CERT_PATH}", "DOCKER_TLS_VERIFY=${DOCKER_TLS_VERIFY}"]) {
                    // Keep the last few images, prune older ones
                    sh "docker image prune -a -f --filter \"until=24h\" --filter \"label=trianandji/drupal-app\""
                }
            }
        }
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed! Check logs for details.'
        }
    }
}
