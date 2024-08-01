Gem::Specification.new do |s|
  s.name        = 'sidekiq_current_model_middleware'
  s.version     = '1.1.0'
  s.required_ruby_version = '>= 3.2.0'
  s.summary     = 'Sidekiq Middleware for persisting ActiveSupport::CurrentAttributes with ActiveRecord model support'
  s.description = 'This gem provides Sidekiq middleware that extends the functionality of Sidekiq\'s built-in CurrentAttributes to persist and restore ActiveSupport::CurrentAttributes across Sidekiq jobs, with added support for ActiveRecord models. It uses GlobalID for serialization and deserialization of ActiveRecord objects, allowing seamless integration with Rails applications to maintain context between web requests and background jobs. The middleware supports multiple CurrentAttributes classes and handles both client-side and server-side persistence.'
  s.authors     = ['Zavier Miller']
  s.email       = 'zavierjmiller@gmail.com'
  s.files       = ['lib/sidekiq_current_model_middleware.rb']
  s.require_paths = 'lib'
  s.homepage =
    'https://rubygems.org/gems/sidekiq_current_model_middleware'
  s.license = 'LGPLv3'

  s.add_dependency 'rails', '>= 7'
  s.add_dependency 'sidekiq', '~> 7.0'

  s.add_development_dependency 'codecov'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3.0'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop'
end
