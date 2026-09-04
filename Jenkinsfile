pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ecommerce-backend:${BUILD_NUMBER} ./backend'
            }
        }

        stage('Security Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL ecommerce-backend:${BUILD_NUMBER}'
            }
        }
    }
}
