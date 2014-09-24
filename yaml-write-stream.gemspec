$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'yaml-write-stream/version'

Gem::Specification.new do |s|
  s.name     = "yaml-write-stream"
  s.version  = ::YamlWriteStream::VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron"

  s.description = s.summary = "An easy, streaming way to generate YAML."

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.require_path = 'lib'
  s.files = Dir["{lib,spec}/**/*", "Gemfile", "History.txt", "README.md", "Rakefile", "yaml-write-stream.gemspec"]
end
