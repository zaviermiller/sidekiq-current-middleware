# frozen_string_literal: true

require 'active_record'

# Resets the database, except when we are only running a specific spec
ARGV.grep(/\w+_spec\.rb/).empty? && ActiveRecord::Schema.define(version: 1) do
  create_table :accounts, force: true do |t|
    t.column :name, :string
  end

  create_table :users, force: true do |t|
    t.column :account_id, :integer
    t.column :name, :string
  end

  create_table :projects, force: true do |t|
    t.column :account_id, :integer
    t.column :name, :string
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Account < ApplicationRecord
  has_many :users
  has_many :projects
end

class User < ActiveRecord::Base
  belongs_to :account
end

class Project < ActiveRecord::Base
  belongs_to :account
end
