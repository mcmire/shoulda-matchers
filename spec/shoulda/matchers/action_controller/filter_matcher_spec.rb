require 'spec_helper'

describe Shoulda::Matchers::ActionController::FilterMatcher do
  describe '#matches?' do
    it 'matches when a before hook is in place' do
      controller = define_controller('HookController') do
        before_filter :authenticate_user!
      end

      matcher = use_before_filter(:authenticate_user!)

      expect(matcher.matches?(controller)).to be_true
    end

    it 'does not match when a before hook is missing' do
      controller = define_controller('HookController')

      matcher = use_before_filter(:authenticate_user!)

      expect(matcher.matches?(controller)).to be_false
    end

    it 'matches when an after hook is in place' do
      controller = define_controller('HookController') do
        after_filter :authenticate_user!
      end

      matcher = use_after_filter(:authenticate_user!)

      expect(matcher.matches?(controller)).to be_true
    end

    it 'does not match when a after hook is missing' do
      controller = define_controller('HookController')

      matcher = use_after_filter(:authenticate_user!)

      expect(matcher.matches?(controller)).to be_false
    end
  end

  describe '#failure_message' do
    it 'includes the filter type and name that was expected' do
      controller = define_controller('HookController')
      matcher = use_before_filter(:authenticate_user!)
      message = 'Expected that HookController would have :authenticate_user! as a before_filter'

      matcher.matches?(controller)

      expect(matcher.failure_message).to eq message
    end
  end

  describe '#failure_message_when_negated' do
    it 'includes the filter type and name that was expected' do
      controller = define_controller('HookController') do
        before_filter :authenticate_user!
      end
      matcher = use_before_filter(:authenticate_user!)
      message = 'Expected that HookController would not have :authenticate_user! as a before_filter'

      matcher.matches?(controller)

      expect(matcher.failure_message_when_negated).to eq message
    end
  end

  describe 'description' do
    it 'includes the filter type and name' do
      matcher = use_before_filter(:authenticate_user!)

      expect(matcher.description).to eq 'have :authenticate_user! as a before_filter'
    end
  end
end
