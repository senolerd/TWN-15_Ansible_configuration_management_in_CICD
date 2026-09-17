import groovy.json.JsonSlurperClassic

def getAnsibleServerIp(){
    withCredentials([
            usernamePassword(
                credentialsId: 'aws_acc_key_and_sec', 
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY', 
            )
        ]) {
            return sh(
                script: "ansible-inventory -i $PROJECT_DIR/ansible/dyn-hosts.aws_ec2.yaml --host AnsibleGroup_ansible_controller | python3 -c \"import sys, json; print(json.load(sys.stdin)['private_ip_address'])\"",
                returnStdout: true
            ).trim()
        }
}

def copyConfigsToAnsibleController(){
    sshagent(credentials: ['devops_ssh_priv'], executable: '') {
        withCredentials([sshUserPrivateKey(credentialsId: 'devops_ssh_priv', keyFileVariable: 'devops_ssh_priv_key')]) {
            sh 'ssh -o StrictHostKeyChecking=no ubuntu@$ANSIBLE_SERVER echo "hello"'
            sh 'scp -p $devops_ssh_priv_key ubuntu@$ANSIBLE_SERVER:~/devops_ssh_priv_key'
            sh 'rsync -av $PROJECT_DIR/ansible ubuntu@$ANSIBLE_SERVER:~/'
            sh 'ssh ubuntu@$ANSIBLE_SERVER ls -al ~/ansible'
        }
    }
}

def runAnsiblePlaybook(){
    sshagent(credentials: ['devops_ssh_priv'], executable: '') {
        withCredentials([usernamePassword(credentialsId: 'aws_acc_key_and_sec', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
            // AWS cli secret will be used for aws dynamic inventory for workstation private address gathering. Passing as scoped to the fn's environment variable
            sh '''
                    ssh ubuntu@$ANSIBLE_SERVER \
                    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
                    AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
                    ANSIBLE_CONFIG=ansible/ansible.cfg \
                    ansible-playbook -i ansible/dyn-hosts.aws_ec2.yaml ansible/deploy-on-workstations.yaml
                '''
        }
    }
}








return this
