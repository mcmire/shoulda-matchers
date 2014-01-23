module Shoulda
  module Matchers
    # @private
    module Integrations
    end
  end
end

if defined?(RSpec)
  require 'shoulda/matchers/integrations/rspec'
end

require 'shoulda/matchers/integrations/test_unit'
