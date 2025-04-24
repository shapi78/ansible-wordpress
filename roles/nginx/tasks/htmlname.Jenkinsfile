pipeline {
    agent any

    parameters {
        string(name: 'USER_NAME', defaultValue: 'default_name', description: 'Enter your name')
    }

    environment {
        ANSIBLE_HOME = '/var/jenkins_home'
        PLAYBOOK_PATH = "${ANSIBLE_HOME}/nginx.yml"
    }

    stages {

        stage('Prepare Environment') {
            steps {
                script {
                    // Ensuring required packages are available
                    sh 'apt-get update && apt-get install -y ansible jq'
                }

                // SSH agent block must be *within* the same steps block
                sshagent(credentials: ['ansible']) {

                    sh '''
                        cp /var/jenkins_home/.ssh/ansible.pem ~/.ssh/id_rsa
                        chmod 600 ~/.ssh/id_rsa
                        ssh-keyscan -H shaked.aws.cts.care >> ~/.ssh/known_hosts
                        echo "SSH connection test:"
                        ssh -o StrictHostKeyChecking=no ubuntu@shaked.aws.cts.care 'echo Connected!'
                    '''
                }
            }
        }

        stage('Execute Ansible Playbook') {
            steps {
                script {
                    // Running the playbook with the parameter
                    sh "ansible-playbook ${/var/jenkins_home/tasks/nginx.yml} -e 'user=${params.USER_NAME}'"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
