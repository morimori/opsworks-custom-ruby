node[:deploy].each do |application, deploy|
  Chef::Log.info("=== Hook: before_migrate for #{release_path}")

  ruby_block 'setup dotenv' do
    block do
      node[:deploy].each do |application, deploy|
        rails_env = deploy[:rails_env]

        Chef::Log.info("Generating dotenv for app: #{application} with env: #{rails_env}...")

        open("#{release_path}/.env.#{rails_env}.local", 'w') do |f|
          deploy[:environment].to_h.each do |name, value|
            f.puts "#{name}=#{value.to_s}"
          end
        end
      end
    end
  end
end
