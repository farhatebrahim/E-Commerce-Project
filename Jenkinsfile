pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '728057823181.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ecommerce-backend:${IMAGE_TAG} ./backend
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    trivy image --severity HIGH,CRITICAL ecommerce-backend:${IMAGE_TAG}
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr'
                ]]) {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REPO}
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    docker tag ecommerce-backend:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }
    }
}
