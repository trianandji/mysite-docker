pipeline {
  agent any

  environment {
    IMAGE_NAME = "trianandji/drupal-app"
  }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: 'main', url: 'https://github.com/trianandji/mysite-docker.git'
      }
    }

    stage('Set Minikube Docker Env') {
      steps {
        script {
          envVars = sh(script: 'minikube docker-env --shell bash', returnStdout: true).trim().split("\n")
          envVars.each { line ->
            def parts = line.tokenize("=")
            if (parts.size() == 2) {
              def key = parts[0].replace('export ', '')
              def value = parts[1].replace('"', '')
              env."${key}" = value
            }
          }
        }
      }
    }

    stage('Build and Tag Docker Image') {
      steps {
        script {
          def buildImageTag = "${IMAGE_NAME}:${env.BUILD_NUMBER}"
          def latestImageTag = "${IMAGE_NAME}:latest"

          withEnv(["DOCKER_HOST=${env.DOCKER_HOST}", "DOCKER_CERT_PATH=${env.DOCKER_CERT_PATH}", "DOCKER_TLS_VERIFY=${env.DOCKER_TLS_VERIFY}"]) {
            sh "docker build -t ${buildImageTag} ."
            sh "docker tag ${buildImageTag} ${latestImageTag}"
            echo "Built and tagged image: ${buildImageTag} and ${latestImageTag}"
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          withEnv(["DOCKER_HOST=${env.DOCKER_HOST}", "DOCKER_CERT_PATH=${env.DOCKER_CERT_PATH}", "DOCKER_TLS_VERIFY=${env.DOCKER_TLS_VERIFY}"]) {
            // Apply deployment as-is first
            sh "kubectl apply -f drupal-deployment.yaml"

            // Update deployment image live without editing file
            sh "kubectl set image deployment/drupal-deployment drupal=${IMAGE_NAME}:${env.BUILD_NUMBER} --record"

            // Wait for rollout to complete
            sh "kubectl rollout status deployment/drupal-deployment --timeout=300s"
          }
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finished."
    }
    success {
      echo 'Deployment successful!'
    }
    failure {
      echo 'Deployment failed! Check logs for details.'
    }
  }
}
