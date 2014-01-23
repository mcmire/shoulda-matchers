module Shoulda
  module Matchers
    module ActiveModel
      # @private
      class CouldNotDetermineValueOutsideOfArray < RuntimeError; end
      # @private
      class NonNullableBooleanError < Shoulda::Matchers::Error; end
    end
  end
end
