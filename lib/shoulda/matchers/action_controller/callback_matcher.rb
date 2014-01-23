module Shoulda
  module Matchers
    module ActionController
      # The `use_before_filter` matcher is used to test that a `before_filter`
      # callback in a controller is called.
      #
      #     class TopicsController < ActionController::Base
      #       before_filter :authenticate_user!
      #       skip_before_filter :prevent_ssl
      #
      #       private
      #
      #       def authenticate_user!; ...; end
      #     end
      #
      #     # RSpec
      #     describe TopicsController do
      #       it { should use_before_filter(:authenticate_user!) }
      #       it { should_not use_before_filter(:prevent_ssl) }
      #     end
      #
      #     # Test::Unit
      #     class TopicsControllerTest < ActionController::TestCase
      #       should use_before_filter(:authenticate_user!)
      #       should_not use_before_filter(:prevent_ssl)
      #     end
      #
      def use_before_filter(callback)
        CallbackMatcher.new(callback, :before, :filter)
      end

      # The `use_after_filter` matcher is used to test that an `after_filter`
      # callback in a controller is called.
      #
      #     class CommentsController < ActionController::Base
      #       after_filter :log_activity
      #       skip_before_filter :destroy_user
      #
      #       private
      #
      #       def log_activity; ...; end
      #     end
      #
      #     # RSpec
      #     describe CommentsController do
      #       it { should use_after_filter(:log_activity) }
      #       it { should_not use_after_filter(:destroy_user) }
      #     end
      #
      #     # Test::Unit
      #     class CommentsControllerTest < ActionController::TestCase
      #       should use_after_filter(:log_activity)
      #       should_not use_after_filter(:destroy_user)
      #     end
      #
      def use_after_filter(callback)
        CallbackMatcher.new(callback, :after, :filter)
      end

      # The `use_before_action` matcher is used to test that a `before_action`
      # callback in a controller is called.
      #
      #     class TopicsController < ActionController::Base
      #       before_action :authenticate_user!
      #       skip_before_action :prevent_ssl
      #
      #       private
      #
      #       def authenticate_user!; ...; end
      #     end
      #
      #     # RSpec
      #     describe TopicsController do
      #       it { should use_before_action(:authenticate_user!) }
      #       it { should_not use_before_action(:prevent_ssl) }
      #     end
      #
      #     # Test::Unit
      #     class TopicsControllerTest < ActionController::TestCase
      #       should use_before_action(:authenticate_user!)
      #       should_not use_before_action(:prevent_ssl)
      #     end
      #
      def use_before_action(callback)
        CallbackMatcher.new(callback, :before, :action)
      end

      # The `use_after_action` matcher is used to test that an `after_action`
      # callback in a controller is called.
      #
      #     class CommentsController < ActionController::Base
      #       after_action :log_activity
      #       skip_before_action :destroy_user
      #
      #       private
      #
      #       def log_activity; ...; end
      #     end
      #
      #     # RSpec
      #     describe CommentsController do
      #       it { should use_after_action(:log_activity) }
      #       it { should_not use_after_action(:destroy_user) }
      #     end
      #
      #     # Test::Unit
      #     class CommentsControllerTest < ActionController::TestCase
      #       should use_after_action(:log_activity)
      #       should_not use_after_action(:destroy_user)
      #     end
      #
      def use_after_action(callback)
        CallbackMatcher.new(callback, :after, :action)
      end

      # The `use_around_filter` matcher is used to test that an `around_filter`
      # callback in a controller is called.
      #
      #     class CommentsController < ActionController::Base
      #       around_action :log_activity
      #       skip_around_action :authenticate_user!
      #
      #       private
      #
      #       def log_activity; ...; end
      #     end
      #
      #     # RSpec
      #     describe CommentsController do
      #       it { should use_around_action(:log_activity) }
      #       it { should_not use_around_action(:authenticate_user!) }
      #     end
      #
      def use_around_filter(callback)
        CallbackMatcher.new(callback, :around, :filter)
      end

      # The `use_around_action` matcher is used to test that an `around_action`
      # callback in a controller is called.
      #
      #     class CommentsController < ActionController::Base
      #       around_action :log_activity
      #       skip_around_action :authenticate_user!
      #
      #       private
      #
      #       def log_activity; ...; end
      #     end
      #
      #     # RSpec
      #     describe CommentsController do
      #       it { should use_around_action(:log_activity) }
      #       it { should_not use_around_action(:authenticate_user!) }
      #     end
      #
      def use_around_action(callback)
        CallbackMatcher.new(callback, :around, :action)
      end

      # @private
      class CallbackMatcher
        def initialize(method_name, kind, callback_type)
          @method_name = method_name
          @kind = kind
          @callback_type = callback_type
        end

        def matches?(controller)
          @controller = controller
          @controller_class = controller.class

          callbacks.map(&:filter).include?(method_name)
        end

        def failure_message
          "Expected that #{controller_class.name} would have :#{method_name} as a #{kind}_#{callback_type}"
        end
        alias failure_message_for_should failure_message

        def failure_message_when_negated
          "Expected that #{controller_class.name} would not have :#{method_name} as a #{kind}_#{callback_type}"
        end
        alias failure_message_for_should_not failure_message_when_negated

        def description
          "have :#{method_name} as a #{kind}_#{callback_type}"
        end

        private

        def callbacks
          controller_class._process_action_callbacks.select do |callback|
            callback.kind == kind
          end
        end

        attr_reader :method_name, :controller, :controller_class, :kind,
          :callback_type
      end
    end
  end
end
