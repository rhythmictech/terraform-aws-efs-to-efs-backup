#!/bin/bash
# sudo yum install amazon-ssm-agent -y
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo start amazon-ssm-agent

# SIM:V4488716 - 08/03/2018 - Support custom DHCP option
# https://github.com/awslabs/efs-backup/issues/1
cat <<EOT | sudo tee /etc/resolv.conf
search amazonaws.com
nameserver 169.254.169.253
EOT

curl --connect-timeout 5 --speed-time 5 --retry 10  --retry-delay 5 https://s3.amazonaws.com/solutions-reference/efs-backup/v1.3.1/efs-ec2-backup.sh -o /home/ec2-user/efs-ec2-backup.sh
curl --connect-timeout 5 --speed-time 5 --retry 10  --retry-delay 5 https://s3.amazonaws.com/solutions-reference/efs-backup/v1.3.1/efs-backup-fpsync.sh -o /home/ec2-user/efs-backup-fpsync.sh

chmod a+x /home/ec2-user/efs-ec2-backup.sh
chmod a+x /home/ec2-user/efs-backup-fpsync.sh

/home/ec2-user/efs-ec2-backup.sh ${SrcEFS} ${DstEFS} ${IntervalTag} ${Retain} ${FolderLabel} ${BackupPrefix}
