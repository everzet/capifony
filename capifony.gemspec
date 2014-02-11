Gem::Specification.new do |spec|

  spec.name         = 'capifony'
  spec.version      = '2.5.1.dev'
  spec.platform     = Gem::Platform::RUBY
  spec.description  = <<-DESC
    Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. This package is a deployment "recipe" to work with symfony (both 1 and 2) applications.
  DESC
  spec.summary      = <<-DESC.strip.gsub(/\n\s+/, " ")
    Deploying symfony PHP applications with Capistrano.
  DESC

  spec.files        = Dir.glob("{bin,lib}/**/*") + %w(README.md LICENSE CHANGELOG.md UPGRADE.md)
  spec.require_path = 'lib'
  spec.has_rdoc     = false

  spec.bindir       = "bin"
  spec.executables << "capifony"

  spec.add_dependency 'capistrano', ">= 2.13.5","<= 2.16.0"
  spec.add_dependency 'colored', ">= 1.2.0"
  spec.add_dependency 'inifile', ">= 2.0.2"
  spec.add_dependency 'capistrano-maintenance', '0.0.3'
  spec.add_dependency 'ruby-progressbar', '1.4.1'

  spec.authors      = [ "Konstantin Kudryashov", "William Durand" ]
  spec.email        = [ "ever.zet@gmail.com", "william.durand1@gmail.com" ]
  spec.homepage     = "http://capifony.org"
  spec.rubyforge_project = "capifony"

  spec.license      = 'MIT'

end
