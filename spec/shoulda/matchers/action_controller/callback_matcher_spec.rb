require 'spec_helper'

describe Shoulda::Matchers::ActionController::CallbackMatcher do
  shared_examples 'CallbackMatcher' do
    describe '#matches?' do
      it 'matches when a before hook is in place' do
        add_callback

        expect(matcher.matches?(controller)).to be_true
      end

      it 'does not match when a before hook is missing' do
        expect(matcher.matches?(controller)).to be_false
      end

      it 'matches when an after hook is in place' do
        add_callback

        expect(matcher.matches?(controller)).to be_true
      end

      it 'does not match when a after hook is missing' do
        expect(matcher.matches?(controller)).to be_false
      end
    end

    describe 'description' do
      it 'includes the filter kind and name' do
        expect(matcher.description).to eq "have :authenticate_user! as a #{kind}_#{callback_type}"
      end
    end

    describe '#failure_message' do
      it 'includes the filter kind and name that was expected' do
        message = "Expected that HookController would have :authenticate_user! as a #{kind}_#{callback_type}"

        matcher.matches?(controller)

        expect(matcher.failure_message).to eq message
      end
    end

    describe '#failure_message_when_negated' do
      it 'includes the filter kind and name that was expected' do
        add_callback
        message = "Expected that HookController would not have :authenticate_user! as a #{kind}_#{callback_type}"

        matcher.matches?(controller)

        expect(matcher.failure_message_when_negated).to eq message
      end
    end

    private

    def matcher
      @matcher ||= described_class.new(:authenticate_user!, kind, callback_type)
    end

    def add_callback
      controller.send("#{kind}_#{callback_type}", :authenticate_user!)
    end

    def controller
      @controller ||= define_controller('HookController')
    end
  end

  describe '#use_before_filter' do
    it_behaves_like 'CallbackMatcher' do
      let(:kind) { :before }
      let(:callback_type) { :filter }
    end
  end

  describe '#use_after_filter' do
    it_behaves_like 'CallbackMatcher' do
      let(:kind) { :after }
      let(:callback_type) { :filter }
    end
  end

  describe '#use_around_filter' do
    it_behaves_like 'CallbackMatcher' do
      let(:kind) { :around }
      let(:callback_type) { :filter }
    end
  end

  if Rails.version.to_i >= 4
    describe '#use_before_action' do
      it_behaves_like 'CallbackMatcher' do
        let(:kind) { :before }
        let(:callback_type) { :action }
      end
    end

    describe '#use_after_action' do
      it_behaves_like 'CallbackMatcher' do
        let(:kind) { :after }
        let(:callback_type) { :action }
      end
    end

    describe '#use_around_action' do
      it_behaves_like 'CallbackMatcher' do
        let(:kind) { :around }
        let(:callback_type) { :action }
      end
    end
  end
end
