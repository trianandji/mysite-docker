  pipeline {
    agent any
    environment {
        ACR_NAME = 'anandcontainerregistry'
        IMAGE_NAME = 'drupal-app-swati'
        IMAGE_TAG = 'v1'
        ACR_URL = "${ACR_NAME}.azurecr.io"
        RESOURCE_GROUP = 'Mydrupalresourcegroup'
        AKS_CLUSTER = 'MyAKSCluster'
        //GIT_CREDENTIALS = credentials('GitAuthTokenAnand')
        PATH = "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:$PATH"
        SHELL = '/bin/bash'
    }

    stages {
        stage('Checkout') {
            steps {
                 git branch: 'dev', 
                     //credentialsId: 'GitAuthTokenAnand',
                     url: 'https://github.com/trianandji/mysite-docker.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                 withEnv([
                     "DOCKER_BUILDKIT=1"
                ]){
                    sh 'docker build --platform linux/amd64,linux/arm64 -t $IMAGE_NAME .'
                    sh 'docker tag $IMAGE_NAME $ACR_URL/$IMAGE_NAME:$IMAGE_TAG'
                }    
            }
        }
        stage('Push to ACR') {
            steps {
                    sh '''
                        az acr login --name ${ACR_NAME}
                        docker push ${ACR_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
               }
          }
        stage('Deploy to AKS') {
            steps { 
                    sh 'az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER}'
                    sh 'kubectl apply -f deployment.yaml'
                    sh 'kubectl apply -f service.yaml'
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

