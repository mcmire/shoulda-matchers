begin
  require 'strong_parameters'
rescue LoadError
end

module Shoulda
  module Matchers
    module ActionController
      def permit(*attributes)
        attributes_and_context = attributes + [self]
        StrongParametersMatcher.new(*attributes_and_context)
      end

      class StrongParametersMatcher
        def self.stubbed_parameters_class
          @stubbed_parameters_class ||= build_stubbed_parameters_class
        end

        def self.build_stubbed_parameters_class
          Class.new(::ActionController::Parameters) do
            include StubbedParameters
          end
        end

        def initialize(*attributes_and_context)
          @attributes = attributes_and_context[0...-1]
          @context = attributes_and_context.last
        end

        def for(action, options = {})
          @action = action
          @verb = options[:verb] || verb_for_action
          self
        end

        def in_context(context)
          @context = context
          self
        end

        def matches?(controller = nil)
          simulate_controller_action && parameters_difference.empty?
        end

        def does_not_match?(controller = nil)
          simulate_controller_action && parameters_difference.present?
        end

        def failure_message
          "Expected controller to permit #{parameters_difference.to_sentence}, but it did not."
        end

        def negative_failure_message
          "Expected controller not to permit #{parameters_difference.to_sentence}, but it did."
        end

        private

        attr_reader :verb, :action, :attributes, :context

        def simulate_controller_action
          ensure_action_and_verb_present!
          stubbed_model_attributes

          context.send(verb, action)

          verify_permit_call
        end

        def verify_permit_call
          @model_attrs.permit_was_called
        end

        def parameters_difference
          attributes - @model_attrs.shoulda_permitted_params
        end

        def stubbed_model_attributes
          @model_attrs = self.class.stubbed_parameters_class.new(arbitrary_attributes)

          local_model_attrs = @model_attrs
          ::ActionController::Parameters.class_eval do
            define_method :[] do |*args|
              local_model_attrs
            end
          end
        end

        def ensure_action_and_verb_present!
          if action.blank?
            raise ActionNotDefinedError
          end
          if verb.blank?
            raise VerbNotDefinedError
          end
        end

        def arbitrary_attributes
          {any_key: 'any_value'}
        end

        def verb_for_action
          verb_lookup = { create: :post, update: :put }
          verb_lookup[action]
        end
      end

      module StubbedParameters
        extend ActiveSupport::Concern

        included do
          attr_accessor :permit_was_called, :shoulda_permitted_params
        end

        def initialize(*)
          @permit_was_called = false
          super
        end

        def permit(*args)
          self.shoulda_permitted_params = args
          self.permit_was_called = true
          nil
        end
      end

      class StrongParametersMatcher::ActionNotDefinedError < StandardError
        def message
          'You must specify the controller action using the #for method.'
        end
      end

      class StrongParametersMatcher::VerbNotDefinedError < StandardError
        def message
          'You must specify an HTTP verb when using a non-RESTful action.' +
          ' e.g. for(:authorize, verb: :post)'
        end
      end
    end
  end
end
