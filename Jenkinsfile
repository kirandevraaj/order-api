pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "kirandevraaj/order-api"
        IMAGE_TAG = "v${env.BUILD_NUMBER}"
        BASTION_HOST = "ubuntu@my-local-bastion"
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo "Checking out application code and K8s manifests from GitHub..."
                checkout scm
            }
        }

        stage('2. Build & Push to Docker Hub') {
            steps {
                echo "Building Docker image ${DOCKER_IMAGE}:${IMAGE_TAG}..."
                // Use the Docker Hub token securely stored in Jenkins credentials vault
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh """
                        echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                        docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} -t ${DOCKER_IMAGE}:latest .
                        echo "Pushing built images to Docker Hub..."
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                    """
                }
            }
        }

        stage('3. Deploy via Bastion Jumpbox') {
            steps {
                echo "Deploying manifests to K8s cluster via secure Bastion gateway..."
                sh """
                    # Create a temporary build-specific directory on the Bastion
                    ssh -o StrictHostKeyChecking=no ${BASTION_HOST} 'mkdir -p ~/k8s-deploy-${BUILD_NUMBER}'
                    
                    # Securely copy Kubernetes manifests from Jenkins over to the Bastion
                    scp -o StrictHostKeyChecking=no -r k8s/* ${BASTION_HOST}:~/k8s-deploy-${BUILD_NUMBER}/
                    
                    # Apply the manifests and update the running deployment image tag
                    ssh -o StrictHostKeyChecking=no ${BASTION_HOST} 'kubectl apply -f ~/k8s-deploy-${BUILD_NUMBER}/'
                    ssh -o StrictHostKeyChecking=no ${BASTION_HOST} 'kubectl set image deployment/order-api-deployment order-api=${DOCKER_IMAGE}:${IMAGE_TAG}'
                """
            }
        }

        stage('4. Verify Rollout & Auto-Rollback') {
            steps {
                echo "Verifying zero-downtime deployment rollout status..."
                script {
                    try {
                        # Wait up to 60 seconds for K8s readiness probes to pass on new pods
                        sh """
                            ssh -o StrictHostKeyChecking=no ${BASTION_HOST} 'kubectl rollout status deployment/order-api-deployment --timeout=60s'
                        """
                        echo "Deployment successful! Service is online with healthy pods."
                    } catch (Exception e) {
                        echo "CRITICAL: Rollout failed or timed out! Initiating automated rollback..."
                        # Instantly revert Kubernetes deployment to the previous stable ReplicaSet
                        sh """
                            ssh -o StrictHostKeyChecking=no ${BASTION_HOST} 'kubectl rollout undo deployment/order-api-deployment'
                        """
                        error("Pipeline failed: New application version failed health checks. Automated rollback to previous stable release completed successfully.")
                    }
                }
            }
        }
    }
    
    // Clean up temporary manifest folders on the Bastion after every run
    post {
        always {
            echo "Cleaning up temporary deployment manifests on Bastion..."
            sh """
                ssh -o StrictHostKeyChecking=no ${BASTION_HOST} 'rm -rf ~/k8s-deploy-${BUILD_NUMBER}' || true
            """
        }
    }
}