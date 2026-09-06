```groovy
pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '728057823181.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend'
        IMAGE_TAG = "${BUILD_NUMBER}"
        BACKEND_INSTANCE_ID = 'i-0de8118cf9561d99d'
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

        stage('Deploy to Backend via SSM') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr'
                ]]) {
                    sh '''
                        COMMAND_ID=$(aws ssm send-command \
                            --region ${AWS_REGION} \
                            --instance-ids ${BACKEND_INSTANCE_ID} \
                            --document-name "AWS-RunShellScript" \
                            --parameters commands="[
                                \\"aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}\\",
                                \\"docker pull ${ECR_REPO}:${IMAGE_TAG}\\",
                                \\"docker stop ecommerce-backend || true\\",
                                \\"docker rm ecommerce-backend || true\\",
                                \\"docker run -d --name ecommerce-backend -p 3001:3000 ${ECR_REPO}:${IMAGE_TAG}\\"
                            ]" \
                            --query 'Command.CommandId' \
                            --output text)

                        echo "SSM Command ID: ${COMMAND_ID}"

                        aws ssm wait command-executed \
                            --region ${AWS_REGION} \
                            --command-id ${COMMAND_ID} \
                            --instance-id ${BACKEND_INSTANCE_ID}

                        aws ssm get-command-invocation \
                            --region ${AWS_REGION} \
                            --command-id ${COMMAND_ID} \
                            --instance-id ${BACKEND_INSTANCE_ID}
                    '''
                }
            }
        }
    }
}
```

