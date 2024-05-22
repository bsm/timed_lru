Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.7'

  s.name        = File.basename(__FILE__, '.gemspec')
  s.summary     = 'Timed LRU'
  s.description = 'Thread-safe LRU implementation with (optional) TTL and constant time operations'
  s.version     = '0.5.2'

  s.authors     = ['Black Square Media']
  s.email       = 'info@blacksquaremedia.com'
  s.homepage    = 'https://github.com/bsm/timed_lru'
  s.license     = 'Apache-2.0'

  s.require_path = 'lib'
  s.files        = `git ls-files`.split("\n")

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop-bsm'
  s.metadata['rubygems_mfa_required'] = 'true'
end
