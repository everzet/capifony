Gem::Specification.new do |spec|

  spec.name = 'capifony'
  spec.version = '2.0.5'
  spec.platform = Gem::Platform::RUBY
  spec.description = <<-DESC
    Capistrano is an open source tool for running scripts on multiple servers. It’s primary use is for easily deploying applications. While it was built specifically for deploying Rails apps, it’s pretty simple to customize it to deploy other types of applications. This package is a deployment “recipe” to work with symfony (both 1 and 2) applications.
  DESC
  spec.summary = <<-DESC.strip.gsub(/\n\s+/, " ")
    Deploying symfony PHP applications with Capistrano.
  DESC

  spec.files = Dir.glob("{bin,lib}/**/*") + %w(README.md LICENSE CHANGELOG)
  spec.require_path = 'lib'
  spec.has_rdoc = false

  spec.bindir = "bin"
  spec.executables << "capifony"

  spec.add_dependency 'capistrano', ">= 2.5.10"

  spec.author = "Konstantin Kudryashov"
  spec.email = "ever.zet@gmail.com"
  spec.homepage = "http://capifony.info"
  spec.rubyforge_project = "capifony"

end
