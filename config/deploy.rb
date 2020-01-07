# frozen_string_literal: true

lock '3.11.2'

set :user, 'wwwuser'
set :repo_url, 'https://github.com/dapi/daily_car_bot.git' if ENV['USE_LOCAL_REPO'].nil?
set :keep_releases, 10
set :linked_files, %w[config/master.key]
set :linked_dirs, %w[log node_modules tmp/pids tmp/cache tmp/sockets public/qrcodes public/assets public/packs config/certs]
set :config_files, fetch(:linked_files)
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:application)}" }

if ENV.has_key? 'BRANCH'
  if ENV['BRANCH']=='ask'
    ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
  else
    set :branch, ENV['BRANCH']
  end
else
  set :branch, 'master'
end

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

set :keep_assets, 2
set :local_assets_dir, 'public'
set :puma_init_active_record, true
set :db_local_clean, false
set :db_remote_clean, true
