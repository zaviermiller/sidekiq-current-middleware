# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

# Codecov is enabled when CI is set to true
# if ENV['CI'] == 'true'
#   puts 'Enabling Simplecov to upload code coverage results to codecov.io'
#   require 'simplecov'
#   SimpleCov.start 'rails' do
#     add_filter '/test/' # Exclude test directory from coverage
#     add_filter '/spec/' # Exclude spec directory from coverage
#     add_filter '/config/' # Exclude config directory from coverage

#     # Add any additional filters or exclusions if needed
#     # add_filter '/other_directory/'

#     add_group 'Lib', '/lib' # Include the lib directory for coverage
#     puts "Tracked files: #{SimpleCov.tracked_files}"
#   end
#   SimpleCov.minimum_coverage 80

#   require 'simplecov-cobertura'
#   SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
# end

require 'active_record/railtie'
require 'action_controller/railtie'
require 'rspec/rails'
require 'active_support/current_attributes'
require 'global_id'

class Current < ActiveSupport::CurrentAttributes
  attribute :account, :user, :project, :request_id

  def user=(resource)
    super
    self.account = resource&.account
  end
end

class Current2 < ActiveSupport::CurrentAttributes
  attribute :user
end

require 'bundler'
Bundler.require(:default, :development)

dbconfig = YAML.safe_load_file(File.join(File.dirname(__FILE__), 'database.yml'))
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))
ActiveRecord::Base.establish_connection(dbconfig['test'])

ActiveRecord::Base.include GlobalID::Identification
GlobalID.app = 'sidekiq-middleware-current'

require 'schema'

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = true
  config.use_transactional_fixtures = false

  config.after(:each) do
    Current.reset
  end
end
