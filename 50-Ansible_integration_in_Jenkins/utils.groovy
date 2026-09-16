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
                script: "ansible-inventory -i $PROJECT_DIR/ansible/dyn-hosts.aws_ec2.yaml --host tag_AnsibleGroup_ansible_controller | python3 -c \"import sys, json; print(json.load(sys.stdin)['public_dns_name'])\"",
                returnStdout: true
            ).trim()
        }
}

return this