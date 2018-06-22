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
      	stage ('Commit to Local Jenkins Build Workspace') {
          	steps {
            	sh 'git add .'
                sh 'git diff --quiet && git diff --staged --quiet || git commit -am "Successfully tested via Jenkins"'
            }
        }
        stage ('Deploy to Heroku via GitHub Organization') {
            steps {
            	sh 'git remote add heroku https://infamousjoeg:b8c3b78e7366eccb888ac5557f1153bc8cd28c22@github.com/infamousjoeg/breaking-butler.git'
            	sh 'git push heroku master'
            }
        }
    }
}
