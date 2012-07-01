namespace :deploy do
  namespace :web do
    desc "Use symfony 1.4 task to disable the application"
    task :disable, :roles => :web, :except => { :no_release => true } do
      symfony.project.disable
    end

    desc "Use symfony 1.4 task to enable the application"
    task :enable, :roles => :web, :except => { :no_release => true } do
      symfony.project.enable
    end
  end
end
