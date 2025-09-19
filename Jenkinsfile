pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '1'))
        disableConcurrentBuilds()
    }
    
    environment {
        REGTEST_JAR = 'jarfiles/RegTestRunner-8.10.5.jar'
    }
    
    triggers {
        pollSCM('H/5 * * * *')  // Poll GitHub every 5 minutes
    }
    
    parameters {
        choice(name: 'XUMLC', choices: ['jarfiles/xumlc-7.20.0.jar'], description: 'Location of the xUML Compiler')
        choice(name: 'REGTEST', choices: ['jarfiles/RegTestRunner-8.10.5.jar'], description: 'Location of the Regression Test Runner')
        string(name: 'BRIDGE_HOST', defaultValue: 'ec2-52-74-183-0.ap-southeast-1.compute.amazonaws.com', description: 'Bridge host address')
        string(name: 'BRIDGE_USER', defaultValue: 'jprocero', description: 'Bridge username')
        password(name: 'BRIDGE_PASSWORD', defaultValue: 'jprocero', description: 'Bridge password')
        string(name: 'BRIDGE_PORT', defaultValue: '11165', description: 'Bridge port')
        string(name: 'CONTROL_PORT', defaultValue: '21176', description: 'Control port')
    }


     
    stages {
        stage('Build') {
            steps {
                dir('.') {
                    bat """
                        java -jar ${params.XUMLC} -uml uml/BuilderUML.xml
                        if errorlevel 1 exit /b 1
                        echo Build completed successfully
                        dir repository\\BuilderUML\\*.rep
                    """
                    archiveArtifacts artifacts: 'repository/BuilderUML/*.rep'
                }
            }
        }
         stage('Deploy') {
            steps {
                dir('.') {
                    bat """
                        echo Checking for repository files...
                       
                        if not exist repository\\BuilderUML\\regtestlatest.rep (
                            echo ERROR: regtestlatest.rep not found!
                            exit /b 1
                        )
                         
                        echo All repository files found, starting deployment...
                        npx e2e-bridge-cli deploy repository/BuilderUML/regtestlatest.rep -h ${params.BRIDGE_HOST} -u ${params.BRIDGE_USER} -P ${params.BRIDGE_PASSWORD} -o overwrite
                        
                    """
                }
            }
        }
        stage('List Test Suites') {
            steps {
                dir('regressiontest') {
                    bat """
                        echo Listing available test suites...
                        java -jar ${REGTEST} -project . -list
                        echo.
                        echo Checking project structure...
                        dir /s testsuite
                        echo.
                        echo Checking if testsuite.xml exists...
                        if exist testsuite\\testsuite.xml (
                            echo testsuite.xml found
                            type testsuite\\testsuite.xml | findstr "testcase"
                        ) else (
                            echo testsuite.xml not found
                        )
                    """
                }
            }
        }
        stage('Test') {
            steps {
                dir('.') {
                    bat """
                        echo Starting regression tests...
                        echo Using RegTest jar: ${params.REGTEST}
                        
                        echo Checking if regtest jar exists...
                        if not exist "${params.REGTEST}" (
                            echo ERROR: RegTest jar not found at ${params.REGTEST}
                            exit /b 1
                        )
                        
                        echo Checking if test cases exist...
                        if not exist "regressiontest\\testsuite\\testsuite.xml" (
                            echo ERROR: Test cases not found in regressiontest directory
                            echo Please ensure regressiontest/testsuite/testsuite.xml exists
                            exit /b 1
                        )
                        
                        echo Starting regression tests...
                        echo Test configuration:
                        echo - Project: .
                        echo - Host: ${params.BRIDGE_HOST}
                        echo - Port: ${params.BRIDGE_PORT}
                        echo - Control Port: ${params.CONTROL_PORT}
                        echo - Username: ${params.BRIDGE_USER}
                        echo - Note: RegTestRunner will run all available test suites in the project
                        
                        echo.
                        echo Checking available test suites...
                        java -jar "${params.REGTEST}" -project . -host ${params.BRIDGE_HOST} -port ${params.BRIDGE_PORT} -username ${params.BRIDGE_USER} -password ${params.BRIDGE_PASSWORD} -list
                        
                        echo.
                        echo Running all available regression tests...
                        echo Command: java -jar "${params.REGTEST}" -project . -host ${params.BRIDGE_HOST} -port ${params.BRIDGE_PORT} -username ${params.BRIDGE_USER} -password ${params.BRIDGE_PASSWORD} -logfile regressiontest/result.xml
                        java -jar "${params.REGTEST}" -project . -host ${params.BRIDGE_HOST} -port ${params.BRIDGE_PORT} -username ${params.BRIDGE_USER} -password ${params.BRIDGE_PASSWORD} -logfile regressiontest/result.xml
                        
                        echo.
                        echo Checking if result.xml was created...
                        if exist regressiontest\\result.xml (
                            echo result.xml found, displaying contents:
                            type regressiontest\\result.xml
                        ) else (
                            echo ERROR: result.xml was not created!
                        )
                        
                        if errorlevel 1 (
                            echo Tests completed with errors - exit code 1
                        ) else (
                            echo Tests completed successfully - exit code 0
                        )
                    """
                }
            }
            post {
                always {
                    script {
                        if (fileExists('regressiontest/result.xml')) {
                            def resultContent = readFile('regressiontest/result.xml')
                            echo "Processing test results..."
                            
                            // Check if we have actual test results
                            if (resultContent.contains('tests="0"') || resultContent.contains('testsuite name=""')) {
                                echo "No test results found in result.xml - this may indicate test configuration issues"
                                echo "Result content: ${resultContent}"
                                echo "This usually means the RegTestRunner couldn't find or execute any tests"
                            } else {
                                echo "Test results found and processed successfully"
                                echo "Result content: ${resultContent}"
                            }
                            
                            // Always publish results for Jenkins reporting
                            junit 'regressiontest/result.xml'
                            archiveArtifacts artifacts: 'regressiontest/result.xml'
                            
                            // Also archive test case files for debugging
                            archiveArtifacts artifacts: 'regressiontest/.$output/**/*'
                            
                        } else {
                            echo "No test results file found - this indicates a test execution problem"
                            // Create a failure result for Jenkins
                            writeFile file: 'regressiontest/result.xml', text: '''<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
   <testsuite name="BuilderUML Regression Tests" tests="1" failures="1" errors="0" skipped="0">
      <testcase name="TestExecutionFailure" classname="RegressionTest">
         <failure message="Test execution failed - result.xml was not generated"/>
      </testcase>
   </testsuites>
</testsuites>'''
                            junit 'regressiontest/result.xml'
                        }
                    }
                }
            }
        }
    }
}