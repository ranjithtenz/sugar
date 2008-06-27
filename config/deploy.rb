require 'mongrel_cluster/recipes'

set :application, "b3s"
set :repository,  "http://svn.elektronaut.no/svn/b3s/trunk"
set :runner,      "app"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "b3s.elektronaut.no"
role :web, "b3s.elektronaut.no"
role :db,  "b3s.elektronaut.no", :primary => true

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

set :mongrel_conf, "#{deploy_to}/#{current_dir}/config/mongrel_cluster.yml"
#set :flush_cache, true

desc "Create shared directories"
task :create_shared_dirs, :roles => [:web,:app] do
	run "mkdir -m 777 #{deploy_to}/#{shared_dir}/cache"
	run "mkdir -m 777 #{deploy_to}/#{shared_dir}/public_cache"
	run "mkdir -m 777 #{deploy_to}/#{shared_dir}/sockets"
	run "mkdir -m 777 #{deploy_to}/#{shared_dir}/sessions"
	run "mkdir -m 777 #{deploy_to}/#{shared_dir}/index"
end

desc "Fix permissions"
task :fix_permissions, :roles => [:web, :app] do
	run "chmod a+rw   #{deploy_to}/#{current_dir}/public/plugin_assets"
	run "chmod -R a+x #{deploy_to}/#{current_dir}/script/*"
	run "chmod a+x    #{deploy_to}/#{current_dir}/public/dispatch.*"
	run "chmod a+rwx  #{deploy_to}/#{current_dir}/public"
end

desc "Create symlinks"
task :create_symlinks, :roles => [:web,:app] do
	run "ln -s #{deploy_to}/#{shared_dir}/cache #{deploy_to}/#{current_dir}/tmp/cache"
	run "ln -s #{deploy_to}/#{shared_dir}/sockets #{deploy_to}/#{current_dir}/tmp/sockets"
	run "ln -s #{deploy_to}/#{shared_dir}/sessions #{deploy_to}/#{current_dir}/tmp/sessions"
	run "ln -s #{deploy_to}/#{shared_dir}/index #{deploy_to}/#{current_dir}/index"
	run "ln -s #{deploy_to}/#{shared_dir}/public_cache #{deploy_to}/#{current_dir}/public/cache"
end

after "deploy:setup", :create_shared_dirs
after "deploy:symlink", :fix_permissions
after "deploy:symlink", :create_symlinks


