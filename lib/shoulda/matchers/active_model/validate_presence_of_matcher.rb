module Shoulda
  module Matchers
    module ActiveModel
      # The `validate_presence_of` matcher tests usage of the
      # `validates_presence_of` validation.
      #
      #     class Robot < ActiveRecord::Base
      #       validates_presence_of :arms
      #     end
      #
      #     # RSpec
      #     describe Robot do
      #       it { should validate_presence_of(:arms) }
      #     end
      #
      #     # Test::Unit
      #     class RobotTest < ActiveSupport::TestCase
      #       should validate_presence_of(:arms)
      #     end
      #
      # #### Qualifiers
      #
      # ##### with_message
      #
      # Use `with_message` if you are using a custom validation message.
      #
      #     class Robot < ActiveRecord::Base
      #       validates_presence_of :legs, message: 'Robot has no legs'
      #     end
      #
      #     # RSpec
      #     describe Robot do
      #       it { should validate_presence_of(:legs).with_message('Robot has no legs') }
      #     end
      #
      #     # Test::Unit
      #     class RobotTest < ActiveSupport::TestCase
      #       should validate_presence_of(:legs).with_message('Robot has no legs')
      #     end
      #
      # @return [ValidatePresenceOfMatcher]
      #
      def validate_presence_of(attr)
        ValidatePresenceOfMatcher.new(attr)
      end

      # @private
      class ValidatePresenceOfMatcher < ValidationMatcher
        def with_message(message)
          @expected_message = message if message
          self
        end

        def matches?(subject)
          super(subject)
          @expected_message ||= :blank
          disallows_value_of(blank_value, @expected_message)
        end

        def description
          "require #{@attribute} to be set"
        end

        private

        def blank_value
          if collection?
            []
          else
            nil
          end
        end

        def collection?
          if reflection
            [:has_many, :has_and_belongs_to_many].include?(reflection.macro)
          else
            false
          end
        end

        def reflection
          @subject.class.respond_to?(:reflect_on_association) &&
            @subject.class.reflect_on_association(@attribute)
        end
      end
    end
  end
end
