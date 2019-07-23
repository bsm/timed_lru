Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.4.0'

  s.name        = File.basename(__FILE__, '.gemspec')
  s.summary     = 'Timed LRU'
  s.description = 'Thread-safe LRU implementation with (optional) TTL and constant time operations'
  s.version     = '0.4.0'

  s.authors     = ['Black Square Media']
  s.email       = 'info@blacksquaremedia.com'
  s.homepage    = 'https://github.com/bsm/timed_lru'

  s.require_path = 'lib'
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
end
