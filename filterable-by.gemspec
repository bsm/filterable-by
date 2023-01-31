Gem::Specification.new do |s|
  s.name        = 'filterable-by'
  s.version     = '0.6.4'
  s.authors     = ['Dimitrij Denissenko']
  s.email       = ['dimitrij@blacksquaremedia.com']
  s.summary     = 'Generate white-listed filter scopes from URL parameter values'
  s.description = 'ActiveRecord plugin'
  s.homepage    = 'https://github.com/bsm/filterable-by'
  s.license     = 'MIT'

  s.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^spec/}) }
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7'

  s.add_dependency 'activerecord'
  s.add_dependency 'activesupport'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop-bsm'
  s.add_development_dependency 'sqlite3'
  s.metadata['rubygems_mfa_required'] = 'true'
end
