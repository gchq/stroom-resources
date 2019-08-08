AWS_INVENTORY=~/work/stroom-resources/ansible/aws/build/aws_inventory.csv
alias sshaws='ssh centos@$(echo $(cat $AWS_INVENTORY | fzf) | cut -d "," -f3) -i ~/.ssh/stroom_aws_key.pem'

alias ap='ansible-playbook'
