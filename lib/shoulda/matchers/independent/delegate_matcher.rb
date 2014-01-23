module Shoulda
  module Matchers
    module Independent
      # The `delegate_method` matcher is used for testing that methods are
      # delegated properly.
      #
      #     class TestRunner
      #       extend Forwardable
      #
      #       def_delegators :suite_runner, :configuration
      #
      #       def initialize(suite_runner)
      #         @suite_runner = suite_runner
      #       end
      #
      #       private
      #
      #       attr_reader :suite_runner
      #     end
      #
      #     # RSpec
      #     describe TestRunner do
      #       it { should delegate_method(:configuration).to(:suite_runner) }
      #     end
      #
      #     # Test::Unit
      #     class TestRunnerTest < ActiveSupport::TestCase
      #       should delegate_method(:configuration).to(:suite_runner)
      #     end
      #
      # #### Qualifiers
      #
      # ##### as
      #
      # Use `as` to specify the name of the method on the delegate object.
      #
      #     class User
      #       def initialize(company)
      #         @company = company
      #       end
      #
      #       def company_name
      #         company.name
      #       end
      #
      #       private
      #
      #       attr_reader :company
      #     end
      #
      #     # RSpec
      #     describe User do
      #       it { should delegate(:company_name).to(:company).as(:name) }
      #     end
      #
      #     # Test::Unit
      #     class UserTest < ActiveSupport::TestCase
      #       should delegate(:company_name).to(:company).as(:name)
      #     end
      #
      # ##### with_arguments
      #
      # Use `with_arguments` to specify that the target method should be called
      # with the given arguments.
      #
      #     class Address
      #       def initialize(geocoding_service)
      #         @geocoding_service = geocoding_service
      #       end
      #
      #       def geocode
      #         geocoding_service.geocode(to_s)
      #       end
      #
      #       def to_s
      #         [street, city, state, zip].join(' ')
      #       end
      #
      #       private
      #
      #       attr_reader :geocoding_service
      #     end
      #
      #     # RSpec
      #     describe Address do
      #       it 'delegates #geocode to the GeocodingService' do
      #         address = Address.new(:geocoding_service)
      #         address.stubs(:to_s).returns('the address')
      #         expect(address).to delegate(:geocode).
      #           to(:geocoding_service).
      #           with_arguments('the address')
      #       end
      #     end
      #
      #     # Test::Unit
      #     class AddressTest < ActiveSupport::TestCase
      #       should 'delegate #geocode to the GeocodingService' do
      #         address = Address.new(:geocoding_service)
      #         address.stubs(:to_s).returns('the address')
      #         matcher = delegate(:geocode).
      #           to(:geocoding_service).
      #           with_arguments('the address')
      #         assert_accepts matcher, address
      #       end
      #     end
      #
      def delegate_method(delegating_method)
        DelegateMatcher.new(delegating_method)
      end

      # @private
      class DelegateMatcher
        def initialize(delegating_method)
          @delegating_method = delegating_method
          @method_on_target = @delegating_method
          @target_double = Doublespeak::ObjectDouble.new

          @delegated_arguments = []
          @target_method = nil
          @subject = nil
          @subject_double_collection = nil
        end

        def matches?(subject)
          @subject = subject

          ensure_target_method_is_present!

          subject_has_delegating_method? &&
            subject_has_target_method? &&
            subject_delegates_to_target_correctly?
        end

        def description
          add_clarifications_to(
            "delegate method ##{delegating_method} to :#{target_method}"
          )
        end

        def to(target_method)
          @target_method = target_method
          self
        end

        def as(method_on_target)
          @method_on_target = method_on_target
          self
        end

        def with_arguments(*arguments)
          @delegated_arguments = arguments
          self
        end

        def failure_message
          base = "Expected #{formatted_delegating_method_name} to delegate to #{formatted_target_method_name}"
          add_clarifications_to(base)
          base << "\nCalls on #{formatted_target_method_name}:"
          base << formatted_calls_on_target
          base.strip
        end
        alias failure_message_for_should failure_message

        def failure_message_when_negated
          base = "Expected #{formatted_delegating_method_name} not to delegate to #{formatted_target_method_name}"
          add_clarifications_to(base)
          base << ', but it did'
        end
        alias failure_message_for_should_not failure_message_when_negated

        private

        attr_reader \
          :delegated_arguments,
          :delegating_method,
          :method,
          :method_on_target,
          :subject,
          :subject_double_collection,
          :target_double,
          :target_method

        def add_clarifications_to(message)
          if delegated_arguments.any?
            message << " with arguments: #{delegated_arguments.inspect}"
          end

          if method_on_target != delegating_method
            message << " as ##{method_on_target}"
          end

          message
        end

        def formatted_delegating_method_name
          formatted_method_name_for(delegating_method)
        end

        def formatted_target_method_name
          formatted_method_name_for(target_method)
        end

        def formatted_method_name_for(method_name)
          if subject.is_a?(Class)
            subject.name + '.' + method_name.to_s
          else
            subject.class.name + '#' + method_name.to_s
          end
        end

        def target_received_method?
          calls_to_method_on_target.any?
        end

        def target_received_method_with_delegated_arguments?
          calls_to_method_on_target.any? do |call|
            call.args == delegated_arguments
          end
        end

        def subject_has_delegating_method?
          subject.respond_to?(delegating_method)
        end

        def subject_has_target_method?
          subject.respond_to?(target_method)
        end

        def ensure_target_method_is_present!
          if target_method.blank?
            raise TargetNotDefinedError
          end
        end

        def subject_delegates_to_target_correctly?
          register_subject_double_collection

          Doublespeak.with_doubles_activated do
            subject.public_send(delegating_method, *delegated_arguments)
          end

          if delegated_arguments.any?
            target_received_method_with_delegated_arguments?
          else
            target_received_method?
          end
        end

        def register_subject_double_collection
          double_collection =
            Doublespeak.register_double_collection(subject.singleton_class)
          double_collection.register_stub(target_method).
            to_return(target_double)

          @subject_double_collection = double_collection
        end

        def calls_to_method_on_target
          target_double.calls_to(method_on_target)
        end

        def calls_on_target
          target_double.calls
        end

        def formatted_calls_on_target
          string = ""

          if calls_on_target.any?
            string << "\n"
            calls_on_target.each_with_index do |call, i|
              name = call.method_name
              args = call.args.map { |arg| arg.inspect }.join(', ')
              string << "#{i+1}) #{name}(#{args})\n"
            end
          else
            string << " (none)"
          end

          string
        end

        # @private
        class TargetNotDefinedError < StandardError
          def message
            'Delegation needs a target. Use the #to method to define one, e.g.
            `post_office.should delegate(:deliver_mail).to(:mailman)`'.squish
          end
        end
      end
    end
  end
end
