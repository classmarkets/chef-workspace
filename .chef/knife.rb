here = File.expand_path File.dirname __FILE__
user = ENV['USER']

log_level                :info
log_location             STDOUT
node_name                user
client_key               "#{here}/#{user}.pem"
validation_client_name   "chef-validator"
validation_key           "#{here}/chef-validator.pem"
chef_server_url          "https://chef.classmarkets.com"
syntax_check_cache_path  "#{here}/syntax_check_cache"
cookbook_path            "cookbooks"

if ::File.exist?("#{here}/knife.local.rb")
  Chef::Config.from_file("#{here}/knife.local.rb")
end
