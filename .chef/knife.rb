# See https://docs.chef.io/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "normseth"
client_key               "#{current_dir}/normseth.pem"
validation_client_name   "nikormseth-validator"
validation_key           "#{current_dir}/nikormseth-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/nikormseth"
syntax_check_cache_path  "#{ENV['HOME']}/.chef/syntaxcache"
cookbook_path            ["#{current_dir}/../cookbooks"]
chef_repo_path            ["#{current_dir}/.."]
