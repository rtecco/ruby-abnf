# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{abnf}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ryan Tecco"]
  s.autorequire = %q{abnf}
  s.date = %q{2009-02-26}
  s.description = %q{A Ruby library for implementing parsers specified with Augmented Backus Naur Form (ABNF).}
  s.email = %q{rt@karmalab.org}
  s.extra_rdoc_files = ["README", "TODO"]
  s.files = ["README", "TODO"]
  s.has_rdoc = true
  s.homepage = %q{http://karmalab.org/~rt}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{A Ruby library for implementing parsers specified with Augmented Backus Naur Form (ABNF).}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
