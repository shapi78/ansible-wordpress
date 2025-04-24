pipeline {
    agent any

    parameters {
        string(name: 'ENV', defaultValue: 'dev', description: 'Environment name')
        string(name: 'VERSION', defaultValue: '1.0.0', description: 'Version to deploy')
    }

    environment {
        CONSUL_HOST = 'http://consul:8500'
    }

    stages {
        stage('Print Params') {
            steps {
                echo "ENV: ${params.ENV}"
                echo "VERSION: ${params.VERSION}"
            }
        }

        stage('Push to Consul') {
            steps {
                script {
                    // Push ENV param
                    sh """
                        curl --request PUT \
                          --data '${params.ENV}' \
                          ${CONSUL_HOST}/v1/kv/project/config/env
                    """

                    // Push VERSION param
                    sh """
                        curl --request PUT \
                          --data '${params.VERSION}' \
                           ${CONSUL_HOST}/v1/kv/project/config/env
                    """
                }
            }
        }
    }
}