pipeline {
    agent any

    stages {
        stage ('Initialize Process') {
            steps {
                deleteDir()
            }
        }
        stage ('Checkout SCM') {
            steps {
                sh 'git clone https://infamousjoeg:5c32f1507f5355ae48cc420c9dda2175c7090710@github.com/infamousjoeg/x213x-prereg-demo.git'
            }
        }
        stage ('Test Python/Flask/PostgreSQL') {
            steps {
                // Things will eventually be done here for testing
            }
        }
        stage ('Commit to internal Private SCM') {
            steps {
                sh 'git add .'
                sh 'git commit -m "Successfully tested via Jenkins"'
                sh 'git remote add origin infamousjoeg:5c32f1507f5355ae48cc420c9dda2175c7090710@github.com/hacker213/demo-poc.git'
                sh 'git push origin master'
            }
        }
        stage ('Deploy to Heroku Cloud') {
            steps {
                sh 'git remote add origin git:295a5656-7c87-234d-bf8d-678e401804a0@heroku.com/x213x-prereg-demo.git'
                sh 'git push origin master'
            }
        }
    }
}