import groovy.json.JsonSlurperClassic

def getAnsibleServerIp(){

    withCredentials([
            usernamePassword(
                credentialsId: 'aws_acc_key_and_sec', 
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY', 
            )
        ]) {
            // def public_dns = sh(
            return sh(
                script: "ansible-inventory -i $SUBDIR/ansible/dyn-hosts.aws_ec2.yaml --host tag_AnsibleGroup_ansible_controller | python3 -c \"import sys, json; print(json.load(sys.stdin)['public_dns_name'])\"",
                returnStdout: true
            ).trim()
            // echo "Ansible Controller Public DNS: ${public_dns}"
        }
}

return this