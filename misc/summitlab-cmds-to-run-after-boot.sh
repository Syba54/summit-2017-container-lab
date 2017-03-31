cat <<EOF >> /etc/hosts

192.168.124.99 cdk cdk.example.com
192.168.124.99 wordpress-devel.cdk.example.com
192.168.124.99 mariadb-devel.cdk.example.com

192.168.124.100 atomic-host atomic-host.example.com
192.168.124.100 wordpress-production.atomic-host.example.com
192.168.124.100 mariadb-production.atomic-host.example.com
EOF


virsh net-destroy default
virsh net-undefine default
virsh net-define /dev/stdin <<EOF
<network>
  <name>default</name>
  <bridge name="virbr0"/>
  <forward/>
  <ip address="192.168.124.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.124.99" end="192.168.124.99"/>
    </dhcp>
  </ip>
</network>
EOF
virsh net-start default
virsh net-autostart default


curl -L http://192.168.122.1:8000/atomic.xml | virsh define /dev/stdin
#virsh autostart atomic-host
virsh start atomic-host
ssh root@atomic-host systemctl status openshift
ssh root@atomic-host oc login -u system:admin
ssh root@atomic-host oc adm policy add-scc-to-group anyuid system:authenticated

# XXXXXXXXXXXXXXXXXXXXx
# switch to student user
#

minishift setup-cdk
minishift config set show-libmachine-logs true
minishift config set memory 10240
minishift config set cpus 4
mkdir /home/student/.minishift/logs
minishift config set log_dir /home/student/.minishift/logs

minishift start --skip-registration --alsologtostderr --show-libmachine-logs --insecure-registry 172.30.0.0/16 --insecure-registry 192.168.0.0/16 --public-hostname cdk.example.com --routing-suffix cdk.example.com
eval $(minishift docker-env)
docker pull registry.access.redhat.com/rhel7
docker pull registry.access.redhat.com/rhel
oc login -u system:admin
oc adm policy add-scc-to-group anyuid system:authenticated
oc login -u developer
minishift stop

# so that we can 'atomic run' on remote tls docker
sudo yum install http://download.eng.bos.redhat.com/brewroot/packages/atomic/1.16.5/1.el7/x86_64/atomic-1.16.5-1.el7.x86_64.rpm

# shutdown and then run
virt-sparsify --convert qcow2 --compress --tmp /extra-space-2/ /extra-space/cdrom.img /extra-space-2/cdrom-sparse.img