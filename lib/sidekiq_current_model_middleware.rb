# frozen_string_literal: true

# SidekiqCurrentModelMiddleware
#
# This gem provides middleware for Sidekiq to persist ActiveSupport::CurrentAttributes
# across job boundaries, including support for ActiveRecord models.
#
# It extends the functionality of Sidekiq's built-in CurrentAttributes middleware
# by adding serialization and deserialization of ActiveRecord models using GlobalID.
#
# Key features:
# - Persists CurrentAttributes from Rails actions into associated Sidekiq jobs
# - Supports multiple CurrentAttributes classes
# - Handles serialization of ActiveRecord models using GlobalID
# - Provides both client-side and server-side middleware
#
# Usage:
#   SidekiqCurrentModelMiddleware.persist("MyApp::Current")
#   # or for multiple current attributes:
#   SidekiqCurrentModelMiddleware.persist(["MyApp::Current", "MyApp::OtherCurrent"])
#
# This file was modified from https://github.com/sidekiq/sidekiq/blob/main/lib/sidekiq/middleware/current_attributes.rb
# It extends the original implementation to handle serialization and deserialization of ActiveRecord models.

require 'active_support/current_attributes'
require 'active_record'
require 'global_id'
require 'sidekiq/client'
require 'sidekiq'

##
# Automatically save and load any current attributes in the execution context
# so context attributes "flow" from Rails actions into any associated jobs.
# This can be useful for multi-tenancy, i18n locale, timezone, any implicit
# per-request attribute. See +ActiveSupport::CurrentAttributes+.
#
# For multiple current attributes, pass an array of current attributes.
#
# @example
#
#   # in your initializer
#   require "sidekiq_current_model_middleware"
#   SidekiqCurrentModelMiddleware.persist("Myapp::Current")
#   # or multiple current attributes
#   SidekiqCurrentModelMiddleware.persist(["Myapp::Current", "Myapp::OtherCurrent"])
#
# SidekiqCurrentModelMiddleware module
#
# This module provides middleware for Sidekiq to persist ActiveSupport::CurrentAttributes
# across job boundaries, including support for ActiveRecord models.
#
# It extends the functionality of Sidekiq's built-in CurrentAttributes middleware
# by adding serialization and deserialization of ActiveRecord models using GlobalID.
module SidekiqCurrentModelMiddleware
  # Save class
  #
  # Client middleware that saves CurrentAttributes to the Sidekiq job payload.
  # It handles serialization of ActiveRecord models using GlobalID.
  class Save
    include Sidekiq::ClientMiddleware

    # Initialize the Save middleware
    #
    # @param cattrs [Hash] A hash of CurrentAttributes classes to persist
    def initialize(cattrs)
      @cattrs = cattrs
    end

    def call(_, job, _, _)
      @cattrs.each do |(key, strklass)|
        next if job.key?(key)

        # Add the global id if the attribute is an ActiveRecord model
        attrs = strklass.constantize.attributes.transform_values do |attr|
          attr.class <= ActiveRecord::Base ? attr.to_global_id : attr
        end
        # Retries can push the job N times, we don't
        # want retries to reset cattr. #5692, #5090 (from orig Sidekiq repo)
        job[key] = attrs if attrs.any?
      end
      yield
    end
  end

  # Load class
  #
  # Server middleware that loads CurrentAttributes from the Sidekiq job payload.
  # It handles deserialization of ActiveRecord models using GlobalID.
  class Load
    include Sidekiq::ServerMiddleware

    # Initialize the Load middleware
    #
    # @param cattrs [Hash] A hash of CurrentAttributes classes to load
    def initialize(cattrs)
      @cattrs = cattrs
    end

    def call(_, job, _, &block)
      klass_attrs = {}

      @cattrs.each do |(key, strklass)|
        next unless job.key?(key)

        klass_attrs[strklass.constantize] = job[key]
      end

      wrap(klass_attrs.to_a, &block)
    end

    private

    def wrap(klass_attrs, &block)
      klass, attrs = klass_attrs.shift
      return block.call unless klass

      retried = false

      begin
        klass.set(current_attributes(attrs)) do
          wrap(klass_attrs, &block)
        end
      rescue NoMethodError
        raise if retried

        # It is possible that the `CurrentAttributes` definition
        # was changed before the job started processing.
        attrs = attrs.select { |attr| klass.respond_to?(attr) }
        retried = true
        retry
      end
    end

    def current_attributes(attrs)
      attrs.transform_values do |attr|
        GlobalID::Locator.locate(attr) || attr
      end
    end
  end

  class << self
    # Persist CurrentAttributes across Sidekiq job boundaries
    #
    # @param klass_or_array [String, Array<String>] The CurrentAttributes class(es) to persist
    # @param config [Sidekiq::Config] The Sidekiq configuration to use (default: Sidekiq.default_configuration)
    #
    # @example
    #   SidekiqCurrentModelMiddleware.persist("MyApp::Current")
    #   # or for multiple current attributes:
    #   SidekiqCurrentModelMiddleware.persist(["MyApp::Current", "MyApp::OtherCurrent"])
    def persist(klass_or_array, config = ::Sidekiq.default_configuration)
      cattrs = build_cattrs_hash(klass_or_array)

      config.client_middleware.add Save, cattrs
      config.server_middleware.add Load, cattrs
    end

    private

    def build_cattrs_hash(klass_or_array)
      if klass_or_array.is_a?(Array)
        {}.tap do |hash|
          klass_or_array.each_with_index do |klass, index|
            hash[key_at(index)] = klass.to_s
          end
        end
      else
        { key_at(0) => klass_or_array.to_s }
      end
    end

    def key_at(index)
      index.zero? ? 'cattr' : "cattr_#{index}"
    end
  end
end
