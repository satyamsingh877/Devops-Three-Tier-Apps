pipeline {
  agent any
  
  environment {
    AWS_ACCOUNT_ID = '180294201508'
    AWS_REGION = 'eu-north-1'
    ECR_REPO_FRONTEND = 'Devops-Three-Tier-Apps/frontend'
    ECR_REPO_BACKEND = 'Devops-Three-Tier-Apps/backend'
    CLUSTER_NAME = 'Devops-Three-Tier-Apps-cluster'

  }
  
  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/satyamsingh877/Devops-Three-Tier-Apps.git'
      }
    }
    
    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh 'sonar-scanner -Dsonar.projectKey=devops-three-tier-apps -Dsonar.sources=.'
        }
      }
    }
    
    stage('OWASP Dependency Check') {
      steps {
        dependencyCheck additionalArguments: '--scan ./ --format HTML --format JSON --out ./reports', odcInstallation: 'DC'
        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
      }
    }
    
    stage('Build Frontend') {
      steps {
        dir('frontend') {
          sh 'docker build -t frontend:${BUILD_NUMBER} .'
        }
      }
    }
    
    stage('Build Backend') {
      steps {
        dir('backend') {
          sh 'docker build -t backend:${BUILD_NUMBER} .'
        }
      }
    }
    
    stage('Trivy Scan') {
      steps {
        sh 'trivy image --exit-code 1 --severity CRITICAL frontend:${BUILD_NUMBER}'
        sh 'trivy image --exit-code 1 --severity CRITICAL backend:${BUILD_NUMBER}'
      }
    }
    
    stage('Push to ECR') {
      steps {
        script {
          docker.withRegistry("https://${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com", 'ecr:us-east-1:aws-credentials') {
            docker.image("frontend:${BUILD_NUMBER}").push("${ECR_REPO_FRONTEND}:${BUILD_NUMBER}")
            docker.image("backend:${BUILD_NUMBER}").push("${ECR_REPO_BACKEND}:${BUILD_NUMBER}")
          }
        }
      }
    }
    
    stage('Deploy to EKS via ArgoCD') {
      steps {
        script {
          withKubeConfig([credentialsId: 'eks-credentials', serverUrl: '']) {
            sh """
              kubectl apply -f kubernetes/manifests/
              argocd app sync three-tier-app
            """
          }
        }
      }
    }
  }
  
  post {
    always {
      cleanWs()
    }
  }
}
