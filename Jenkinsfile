pipeline {
    agent none
    stages {
        stage('BuildAndZip') {
            matrix {
                agent kernel-builder
                axes {
                    axis {
                        name 'TARGET'
                        values 'aosp', 'memeui'
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
                            sh 'build.sh ${TARGET} ${SU}'
                        }
                    }
                   
                }
            }
        }
    }
}

