Gem::Specification.new do |spec|

  spec.name = 'capifony'
  spec.version = '0.3.3'
  spec.platform = Gem::Platform::RUBY
  spec.description = <<-DESC
    Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. This package is a deployment “recipe” to work with symfony PHP applications.
  DESC
  spec.summary = <<-DESC.strip.gsub(/\n\s+/, " ")
    Deploying symfony PHP applications with Capistrano.
  DESC

  spec.files = Dir.glob("{bin,lib}/**/*") + %w(README LICENSE CHANGELOG)
  spec.require_path = 'lib'
  spec.has_rdoc = false

  spec.bindir = "bin"
  spec.executables << "capifony"

  spec.add_dependency 'capistrano', ">= 2.5.10"

  spec.author = "Konstantin Kudryashov"
  spec.email = "ever.zet@gmail.com"
  spec.homepage = "http://everzet.com/projects/symfony-helpers/capifony"
  spec.rubyforge_project = "capifony"

end
