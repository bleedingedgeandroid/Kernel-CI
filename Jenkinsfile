pipeline {
    agent none
    stages {
        stage('BuildAndZip') {
            matrix {
                agent {
                    node {
                        label 'kernel-builder'
                        customWorkspace "workspace/Android/Murali680-${TARGET}-${SU}" 
                    }
                }
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

