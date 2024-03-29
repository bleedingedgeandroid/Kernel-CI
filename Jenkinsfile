pipeline {
    agent none
    stages {
        stage('BuildAndZip') {
            matrix {
                agent {
                    node {
                        label 'kernel-builder'
                        customWorkspace "workspace/Android/spes/Uvite680-${TARGET}-${SU}-HAS_EROFS+${EROFS}" 
                    }
                }
                axes {
                    axis {
                        name 'TARGET'
                        values 'AOSP'
                    }
                    axis {
                        name 'SU'
                        values 'KSU', 'NONE'
                    }
                    axis {
                        name 'EROFS'
                        values 'NO'
                    }
                }
                stages {
                    stage('Build') {
                        steps {
                            echo "Building for ${TARGET}-${SU}, EROFS Support: ${EROFS}"
                            sh 'chmod +x ./build.sh '
                            sh './build.sh ${TARGET} ${SU} ${EROFS}'
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

