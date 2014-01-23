module Shoulda
  module Matchers
    module ActiveModel
      # The `ensure_exclusion_of` matcher tests usage of the
      # `validates_exclusion_of` validation, asserting that an attribute cannot
      # take a blacklist of values, and inversely, can take values outside of
      # this list.
      #
      # #### Qualifiers
      #
      # `in_array` or `in_range` are used to test usage of the `:in` option,
      # and so one must be used.
      #
      # ##### in_array
      #
      # Use `in_array` if your blacklist is an array of values.
      #
      #     class Game
      #       include ActiveModel::Model
      #
      #       validates_exclusion_of :supported_os, in: ['Mac', 'Linux']
      #     end
      #
      #     # RSpec
      #     describe Game do
      #       it { should ensure_exclusion_of(:supported_os).in_array(['Mac', 'Linux']) }
      #     end
      #
      #     # Test::Unit
      #     class GameTest < ActiveSupport::TestCase
      #       should ensure_exclusion_of(:supported_os).in_array(['Mac', 'Linux'])
      #     end
      #
      # ##### in_range
      #
      # Use `in_range` if your blacklist is a range of values.
      #
      #     class Game
      #       include ActiveModel::Model
      #
      #       validates_exclusion_of :supported_os, in: ['Mac', 'Linux']
      #     end
      #
      #     # RSpec
      #     describe Game do
      #       it { should ensure_exclusion_of(:floors_with_enemies).in_range(5..8) }
      #     end
      #
      #     # Test::Unit
      #     class GameTest < ActiveSupport::TestCase
      #       should ensure_exclusion_of(:floors_with_enemies).in_range(5..8)
      #     end
      #
      # ##### with_message
      #
      # Use `with_message` if you are using a custom validation message.
      #
      #     class Game
      #       include ActiveModel::Model
      #
      #       validates_exclusion_of :weapon,
      #         in: ['pistol', 'paintball gun', 'stick'],
      #         message: 'You chose a puny weapon'
      #     end
      #
      #     # RSpec
      #     describe Game do
      #       it do
      #         should ensure_exclusion_of(:weapon).
      #           in_array(['pistol', 'paintball gun', 'stick']).
      #           with_message('You chose a puny weapon')
      #       end
      #     end
      #
      #     # Test::Unit
      #     class GameTest < ActiveSupport::TestCase
      #       should ensure_exclusion_of(:weapon).
      #         in_array(['pistol', 'paintball gun', 'stick']).
      #         with_message('You chose a puny weapon')
      #     end
      #
      # @return [EnsureExclusionOfMatcher]
      #
      def ensure_exclusion_of(attr)
        EnsureExclusionOfMatcher.new(attr)
      end

      # @private
      class EnsureExclusionOfMatcher < ValidationMatcher
        def in_array(array)
          @array = array
          self
        end

        def in_range(range)
          @range = range
          @minimum = range.first
          @maximum = range.max
          self
        end

        def with_message(message)
          @expected_message = message if message
          self
        end

        def description
          "ensure exclusion of #{@attribute} in #{inspect_message}"
        end

        def matches?(subject)
          super(subject)

          if @range
            allows_lower_value &&
              disallows_minimum_value &&
              allows_higher_value &&
              disallows_maximum_value
          elsif @array
            disallows_all_values_in_array?
          end
        end

        private

        def disallows_all_values_in_array?
          @array.all? do |value|
            disallows_value_of(value, expected_message)
          end
        end

        def allows_lower_value
          @minimum == 0 || allows_value_of(@minimum - 1, expected_message)
        end

        def allows_higher_value
          allows_value_of(@maximum + 1, expected_message)
        end

        def disallows_minimum_value
          disallows_value_of(@minimum, expected_message)
        end

        def disallows_maximum_value
          disallows_value_of(@maximum, expected_message)
        end

        def expected_message
          @expected_message || :exclusion
        end

        def inspect_message
          if @range
            @range.inspect
          else
            @array.inspect
          end
        end
      end
    end
  end
end
