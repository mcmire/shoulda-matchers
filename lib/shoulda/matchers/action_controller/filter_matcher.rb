module Shoulda # :nodoc:
  module Matchers
    module ActionController # :nodoc:
      # Ensure a controller uses a given before_filter
      #
      # Example:
      #
      #   it { should use_before_filter(:authenticate_user!) }
      #   it { should_not use_before_filter(:prevent_ssl) }
      def use_before_filter(filter)
        FilterMatcher.new(filter, :before)
      end

      # Ensure a controller uses a given before_filter
      #
      # Example:
      #
      #   it { should use_after_filter(:log_activity) }
      #   it { should_not use_after_filter(:destroy_user) }
      def use_after_filter(filter)
        FilterMatcher.new(filter, :after)
      end

      class FilterMatcher # :nodoc:
        def initialize(filter, type)
          @filter = filter
          @type = type
        end

        def matches?(subject)
          @subject = subject
          hooks.map(&:filter).include?(filter)
        end

        def failure_message
          "Expected that #{subject.name} would have :#{filter} as a #{type}_filter"
        end
        alias failure_message_for_should failure_message

        def failure_message_when_negated
          "Expected that #{subject.name} would not have :#{filter} as a #{type}_filter"
        end
        alias failure_message_for_should_not failure_message_when_negated

        def description
          "have :#{filter} as a #{type}_filter"
        end

        private

        def hooks
          subject._process_action_callbacks.select { |callback| callback.kind == type }
        end

        attr_reader :filter, :subject, :type
      end
    end
  end
end
