require 'spec_helper'

describe Shoulda::Matchers::ActionController::CallbackMatcher do
  shared_examples 'CallbackMatcher' do |method_name, kind, callback_type|
    let(:matcher) { described_class.new(method_name, kind, callback_type) }

    describe '#matches?' do
      it 'matches when a before hook is in place' do
        add_callback(kind, callback_type, method_name)

        expect(matcher.matches?(controller)).to be_true
      end

      it 'does not match when a before hook is missing' do
        expect(matcher.matches?(controller)).to be_false
      end

      it 'matches when an after hook is in place' do
        add_callback(kind, callback_type, method_name)

        expect(matcher.matches?(controller)).to be_true
      end

      it 'does not match when a after hook is missing' do
        expect(matcher.matches?(controller)).to be_false
      end
    end

    describe 'description' do
      it 'includes the filter kind and name' do
        expect(matcher.description).to eq "have :#{method_name} as a #{kind}_#{callback_type}"
      end
    end

    describe 'failure' do
      it 'includes the filter kind and name that was expected' do
        message = "Expected that HookController would have :#{method_name} as a #{kind}_#{callback_type}"

        expect {
          expect(controller).to send("use_#{kind}_#{callback_type}", method_name)
        }.to fail_with_message(message)
      end
    end

    describe '#failure_message_when_negated' do
      it 'includes the filter kind and name that was expected' do
        add_callback(kind, callback_type, method_name)
        message = "Expected that HookController would not have :#{method_name} as a #{kind}_#{callback_type}"

        expect {
          expect(controller).not_to send("use_#{kind}_#{callback_type}", method_name)
        }.to fail_with_message(message)
      end
    end

    private

    def add_callback(kind, callback_type, callback)
      controller.send("#{kind}_#{callback_type}", callback)
    end

    def controller
      @controller ||= define_controller('HookController')
    end
  end

  describe '#use_before_filter' do
    it_behaves_like 'CallbackMatcher', :authenticate_user!, :before, :filter
  end

  describe '#use_after_filter' do
    it_behaves_like 'CallbackMatcher', :log_activity, :after, :filter
  end

  describe '#use_around_filter' do
    it_behaves_like 'CallbackMatcher', :log_activity, :around, :filter
  end

  if Rails.version.to_i >= 4
    describe '#use_before_action' do
      it_behaves_like 'CallbackMatcher', :authenticate_user!, :before, :action
    end

    describe '#use_after_action' do
      it_behaves_like 'CallbackMatcher', :log_activity, :after, :action
    end

    describe '#use_around_action' do
      it_behaves_like 'CallbackMatcher', :log_activity, :around, :action
    end
  end
end
