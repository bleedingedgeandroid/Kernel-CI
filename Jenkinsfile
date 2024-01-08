pipeline {
    agent none
    options {
        // This is required if you want to clean before build
        skipDefaultCheckout(true)
    }
    stages {
        stage('BuildAndZip') {
            matrix {
                agent {label 'kernel-builder'}
                axes {
                    axis {
                        name 'TARGET'
                        values 'AOSP', 'MIUI'
                    }
                    axis {
                        name 'SU'
                        values 'KSU', 'NONE'
                    }
                }
                stages {
                    stage('Build') {
                        steps {
                            //cleanWs()
                            checkout scm
                            echo "Building for ${TARGET}-${SU}"
                            sh 'chmod +x ./build.sh '
                            sh './build.sh ${TARGET} ${SU}'
                        }
                    }
                }

                post {
                    always {
                        archiveArtifacts artifacts: '*.zip', fingerprint: true
                    }
                }
            }
        }
    }

}

