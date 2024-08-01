# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/client'
require 'active_support/current_attributes'
require 'sidekiq_current_model_middleware'

describe SidekiqCurrentModelMiddleware do
  let(:account) { Account.create(name: 'test') }
  let(:user) { User.create(name: 'bob', account_id: account.id) }

  describe 'load middleware' do
    it 'sets current when provided in message' do
      load = SidekiqCurrentModelMiddleware::Load.new({ 'cattr' => 'Current' })
      load.call(double, { 'something' => 'else', 'cattr' => { 'account' => account.to_global_id } },
                'fake_queue') do
        expect(Current.account).to eq(account)
      end
    end

    it 'does not set current when not provided in message' do
      load = SidekiqCurrentModelMiddleware::Load.new({ 'cattr' => 'Current' })
      load.call(double, { 'something' => 'else' },
                'fake_queue') do
        expect(Current.account).to be_nil
      end
    end

    it 'does not hydrate non-active record objects' do
      load = SidekiqCurrentModelMiddleware::Load.new({ 'cattr' => 'Current' })
      load.call(double, { 'something' => 'else', 'cattr' => { 'request_id' => 1234 } },
                'fake_queue') do
        expect(Current.request_id).to eq(1234)
      end
    end

    it 'works with multiple attributes' do
      load = SidekiqCurrentModelMiddleware::Load.new({ 'cattr' => 'Current' })
      load.call(double, { 'something' => 'else', 'cattr' => { 'account' => account.to_global_id, 'user' => user.to_global_id } },
                'fake_queue') do
        expect(Current.user).to eq(user)
        expect(Current.account).to eq(account)
      end
    end

    it 'works with some hydrated and some not' do
      load = SidekiqCurrentModelMiddleware::Load.new({ 'cattr' => 'Current' })
      load.call(double, { 'something' => 'else', 'cattr' => { 'account' => account.to_global_id, 'request_id' => 1234 } },
                'fake_queue') do
        expect(Current.account).to eq(account)
        expect(Current.request_id).to eq(1234)
      end
    end

    it 'works with multiple currents' do
      load = SidekiqCurrentModelMiddleware::Load.new({ 'cattr0' => 'Current', 'cattr1' => 'Current2' })
      load.call(double, { 'something' => 'else', 'cattr0' => { 'account' => account.to_global_id }, 'cattr1' => { 'user' => user.to_global_id } },
                'fake_queue') do
        expect(Current.account).to eq(account)
        expect(Current2.user).to eq(user)
      end
    end
  end

  describe 'save middleware' do
    it 'saves current in message' do
      save = SidekiqCurrentModelMiddleware::Save.new({ 'cattr' => 'Current' })
      job = {}
      Current.account = account
      save.call(double, job, 'fake_queue', 'fake_pool') do
        expect(GlobalID::Locator.locate(job['cattr'][:account])).to eq(account)
      end
    end
  end
end
