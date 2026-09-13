def getAnsibleServerIp(){

    withCredentials([
            usernamePassword(
                credentialsId: 'aws_acc_key_and_sec', 
                passwordVariable: 'AWS_SECRET_ACCESS_KEY', 
                usernameVariable: 'AWS_ACCESS_KEY_ID'
            )
        ]) {
            def ansible_controller_json = sh(script:"ansible-inventory  --host tag_AnsibleGroup_ansible_controller", returnStdout: true).trim()
            def ansible_controller_data = readJSON text: ansible_controller_json
            echo "Ansible Controller Public DNS: ${ansible_controller_data.public_dns_name}"
        }
}

return this