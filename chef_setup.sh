!#/bin/bash
#Create directory
mkdir -p /etc/cookbooks/google-cloud/recipes
sudo apt update -y && sudo apt install git -y
wget https://packages.chef.io/files/stable/chef/13.8.5/ubuntu/16.04/chef_13.8.5-1_amd64.deb
sudo dpkg -i chef_*
knife cookbook site install google-cloud
cd /etc/cookbooks/
git config --global user.email $git_email
git config --global user.name $git_user
git init
git commit -m genesis --allow-empty
mkdir /etc/account/
account=/etc/account/
cat > $${account}/account.json << EOL
account.json
EOL
cat >  /etc/cookbooks/google-cloud/recipes/default.rb <<EOL
gauth_credential 'mycred' do
  action :serviceaccount
  path ENV['$${account}/account.json'] 
  scopes [
    'https://www.googleapis.com/auth/compute'
  ]
end

gcompute_disk 'instance-test-os-1' do
  action :create
  source_image 'projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts'
  zone '${zone}'
  project ENV['${project}'] 
  credential 'mycred'
end

gcompute_network 'mynetwork-test' do
  action :create
  project ENV['${project}'] 
  credential 'mycred'
end

gcompute_address 'instance-test-ip' do
  action :create
  region '${region}'
  project ENV['${project}'] 
  credential 'mycred'
end

gcompute_instance 'instance-test' do
  action :create
  machine_type '${machine_type}'
  disks [
    {
      boot: true,
      auto_delete: true,
      source: 'instance-test-os-1'
    }
  ]
  network_interfaces [
    {
      network: '${network}',
      access_configs: [
        {
          name: 'External NAT',
          nat_ip: 'instance-test-ip',
          type: 'ONE_TO_ONE_NAT'
        }
      ]
    }
  ]
  zone '${zone}'
  project ENV['${project}'] # ex: 'my-test-project'
  credential 'mycred'
end

EOL 

chef-client --local-mode --runlist 'recipe[google-cloud::default]'
