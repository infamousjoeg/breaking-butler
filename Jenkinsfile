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
                sh 'git clone http://eva:Cyberark1@192.168.0.5:7990/scm/~eva/x213x-prereg-webapp.git'
            }
        }
        stage ('Test Python/Flask/PostgreSQL') {
            steps {
                // Things will eventually be done here for testing
            }
        }
        stage ('Commit to Private GitHub for Organization') {
            steps {
                script {
                    if ($(git ls-remote private)) {
                        sh 'git remote add private https://infamousjoeg:5c32f1507f5355ae48cc420c9dda2175c7090710@github.com/hacker213/demo-poc.git'
                    }
                    sh 'git add .'
                    sh 'git commit -m "Successfully tested via Jenkins"'
                    sh 'git push private master'
                }
            }
        }
        stage ('Deploy to Heroku Cloud') {
            steps {
                    scripts {
                        if ($(git ls-remote heroku)) {
                            sh 'git remote add heroku https://git:f95126dc-897c-463a-a4f5-da31819f6257@github.com/hacker213/demo-poc.git'
                        }
                    }
                sh 'git push origin master'
            }
        }
    }
}
