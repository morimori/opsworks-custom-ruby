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

  %w(bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel).each do |pkg|
    package pkg do
      action :install
    end
  end

  git '/home/deploy/.rbenv' do
    repository 'https://github.com/rbenv/rbenv.git'
    revision 'master'
    user deploy[:user]
    group deploy[:group]
    action :sync
  end

  bash 'build rbenv' do
    code "src/configure && make -C src"
    cwd '/home/deploy/.rbenv'
    user deploy[:user]
    group deploy[:group]
  end

  directory '/home/deploy/.rbenv/plugins' do
    mode 0755
    owner deploy[:user]
    group deploy[:group]
  end

  git '/home/deploy/.rbenv/plugins/ruby-build' do
    repository 'https://github.com/rbenv/ruby-build.git'
    revision 'master'
    user deploy[:user]
    group deploy[:group]
    action :sync
  end

  bash 'setup rbenv' do
    code <<-EOS
      echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
      echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    EOS
    user deploy[:user]
    group deploy[:group]
    not_if { ::File.readlines('/home/deploy/.bash_profile').grep(/eval "\$\(rbenv init \-\)"/).any? }
  end

  ruby_block 'initialize_rbenv' do
    block do
      ENV['RBENV_ROOT'] = '/home/deploy/.rbenv'
      ENV['PATH'] = "/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:#{ENV['PATH']}"
    end
  end

  ruby_version = ::File.read("#{release_path}/.ruby-version").chomp
  bash "install ruby #{ruby_version}" do
    code "rbenv install -s #{ruby_version}"
    user deploy[:user]
    group deploy[:group]
  end

  bash "set global ruby version to #{ruby_version}" do
    code "rbenv global #{ruby_version}"
    user deploy[:user]
    group deploy[:group]
  end

  bash "install bundler" do
    code <<-EOS
      BUNDLER_VERSION=$(grep -A1 '^BUNDLED WITH' Gemfile.lock | tail -n1)
      gem install bundler -v "${BUNDLER_VERSION}" --no-document
    EOS
    user deploy[:user]
    group deploy[:group]
  end

  bash 'bundle install' do
    code "bundle install --path #{deploy[:home]}/.bundler/#{application} --without=#{deploy[:ignore_bundler_groups].join(' ')}"
    cwd release_path
    user deploy[:user]
    group deploy[:group]
  end

end
