Gem::Specification.new do |s|
  s.name        = 'sidekiq-current-middleware'
  s.version     = '1.0.0'
  s.required_ruby_version = '>= 3.2.0'
  s.summary     = 'Sidekiq Middleware to provide hydrated CurrentAttribute fields using ActiveRecord'
  s.description = 'Sidekiq Middleware to provide hydrated CurrentAttribute fields using ActiveRecord'
  s.authors     = ['Zavier Miller']
  s.email       = 'zavierjmiller@gmail.com'
  s.files       = ['lib/sidekiq_middleware_current.rb']
  s.require_paths = 'lib'
  s.homepage =
    'https://rubygems.org/gems/sidekiq-current-middleware'
  s.license = 'MIT'

  s.add_dependency 'rails', '>= 7'
  s.add_dependency 'sidekiq', '>= 6.3'

  s.add_development_dependency 'codecov'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3.0'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop'
end
