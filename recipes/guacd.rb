#
# Cookbook:: tomcat9
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

tmp_path = Chef::Config[:file_cache_path]

group node['guacd']['group'] do
  comment	'psmgwuser group'
  action 	:create
end

user node['guacd']['user'] do
  comment 'guacd user'
  home 	'/home/psmgwuser'
  shell '/sbin/nologin'
  action :create
end

template "/var/tmp/psmgwparms" do
  source 'psmgwparms.erb'
  owner node['guacd']['user']
  group node['guacd']['group']
  mode '0644'
end

#  s3://chef-apac/CARKpsmgw-11.02.0.8.el7.x86_64.rpm
rpm_package 'CARKpsmgw' do
  source "https://chef-apac.s3-ap-southeast-1.amazonaws.com/CARKpsmgw-11.02.0.8.el7.x86_64.rpm"
  action :install
end


#node.default['tomcat']['ssl_certificate'] = /opt/tomcat/pgws_com.pem
bash 'import certificate into jvm keystore' do
  code <<-EOH
  RPATH=`readlink -f /usr/bin/java | sed "s:bin/java::"`; \
  keytool -import -alias webapp_guacd_cert2 -keystore $RPATH/lib/security/cacerts \
  -trustcacerts -file "#{node['tomcat']['ssl_certificate']}" -storepass "#{node['tomcat']['keystore_password']}" -noprompt
  EOH
  action :run
end


template "/etc/guacamole/guacd.conf" do
  source 'guacd.conf.erb'
  owner node['guacd']['user']
  group node['guacd']['group']
  mode '0644'
end

service 'guacd' do
  action [:enable, :start]
end

service 'tomcat' do
  action :restart
end