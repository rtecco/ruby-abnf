require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*.rb']
  t.verbose = true
end

GEM = "abnf"

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = "0.1.0"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "TODO"]
  s.summary = "A Ruby library for implementing parsers specified with Augmented Backus Naur Form (ABNF)."
  s.description = s.summary
  s.author = "Ryan Tecco"
  s.email = "rt@karmalab.org"
  s.homepage = "http://karmalab.org/~rt"
  s.require_path = "lib"
  s.autorequire = GEM
  s.files %w{README Rakefile TODO} + Dir.glob("{lib,test}/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Create the gemspec file."
task :gemspec do
  File.open("#{GEM}.gemspec", "w"){|f| f.puts spec.to_ruby}
end
