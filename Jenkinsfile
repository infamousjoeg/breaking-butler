pipeline {
    agent any

    stages {
        stage ('Initialize Process') {
            steps {
                deleteDir()
            }
        }
        stage ('Checkout from Team Development SCM') {
            steps {
            	sh 'git clone http://eva:Cyberark1@192.168.0.5:7990/scm/~eva/x213x-prereg-webapp.git .'
            }
        }
        stage ('Test Python/Flask/PostgreSQL') {
            steps {
                echo 'Things will eventually be done here for testing.'
            }
        }
      	stage ('Commit to Local Workspace') {
          	steps {
            	sh 'git add .'
                sh 'git commit -am "Successfully tested via Jenkins"'
            }
        }
        stage ('Commit to Private GitHub for Organization') {
            steps {
            	sh 'git remote add private https://infamousjoeg:b8c3b78e7366eccb888ac5557f1153bc8cd28c22@github.com/hacker213/demo-poc.git'
            	sh 'git push private master'
            }
        }
        stage ('Deploy to Heroku Cloud') {
            steps {
            	sh 'git remote add heroku https://git:f95126dc-897c-463a-a4f5-da31819f6257@github.com/hacker213/demo-poc.git'
            	sh 'git push origin master'
            }
        }
    }
}
