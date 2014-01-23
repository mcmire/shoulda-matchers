module Shoulda
  module Matchers
    module ActionController
      # The `route` matcher tests that a route resolves to a controller,
      # action, and params; and that the controller, action, and params
      # generates the same route. For an RSpec suite, this is like using a
      # combination of `route_to` and `be_routable`. For a Test::Unit suite, it
      # provides a more expressive syntax over `assert_routing`.
      #
      # Given these routes:
      #
      #     My::Application.routes.draw do
      #       get '/posts', controller: 'posts', action: 'index'
      #       get '/posts/:id' => 'posts#show'
      #     end
      #
      # You can choose to keep your routing tests under the test file for one
      # controller:
      #
      #     class PostsController < ApplicationController
      #       # ...
      #     end
      #
      #     # RSpec
      #     describe PostsController do
      #       it { should route(:get, '/posts').to(action: :index) }
      #       it { should route(:get, '/posts/1').to(action: :show, id: 1) }
      #     end
      #
      #     # Test::Unit
      #     class PostsControllerTest < ActionController::TestCase
      #       should route(:get, '/posts').to(action: 'index')
      #       should route(:get, '/posts/1').to(action: :show, id: 1)
      #     end
      #
      # Or if you like, you can keep all of your routing tests in one file.
      # Just be sure to always specify a controller as `route` won't be able to
      # figure it out otherwise:
      #
      #     # RSpec
      #     describe 'Routing' do
      #       it { should route(:get, '/posts').to(controller: :posts, action: :index) }
      #       it { should route(:get, '/posts/1').to('posts#show', id: 1) }
      #     end
      #
      #     # Test::Unit
      #     class RoutesTest < ActionController::IntegrationTest
      #       should route(:get, '/posts').to(controller: :posts, action: :index)
      #       should route(:get, '/posts/1').to('posts#show', id: 1)
      #     end
      #
      # @return [RouteMatcher]
      #
      def route(method, path)
        RouteMatcher.new(method, path, self)
      end

      # @private
      class RouteMatcher
        def initialize(method, path, context)
          @method  = method
          @path    = path
          @context = context
        end

        attr_reader :failure_message, :failure_message_when_negated

        alias failure_message_for_should failure_message
        alias failure_message_for_should_not failure_message_when_negated

        def to(*args)
          @params = RouteParams.new(args).normalize
          self
        end

        def in_context(context)
          @context = context
          self
        end

        def matches?(controller)
          guess_controller!(controller)
          route_recognized?
        end

        def description
          "route #{@method.to_s.upcase} #{@path} to/from #{@params.inspect}"
        end

        private

        def guess_controller!(controller)
          @params[:controller] ||= controller.controller_path
        end


        def route_recognized?
          begin
            @context.__send__(:assert_routing,
                          { method: @method, path: @path },
                          @params)

            @failure_message_when_negated = "Didn't expect to #{description}"
            true
          rescue ::ActionController::RoutingError => error
            @failure_message = error.message
            false
          rescue Shoulda::Matchers::AssertionError => error
            @failure_message = error.message
            false
          end
        end
      end
    end
  end
end
