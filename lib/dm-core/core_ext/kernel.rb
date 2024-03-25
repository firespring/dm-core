module Kernel
  # Returns the object's singleton class.
  #
  # @return [Class]
  #
  # @api private
  unless respond_to?(:singleton_class)
    def singleton_class
      class << self
        self
      end
    end
  end

  # Delegates to DataMapper.repository()
  #
  # @api public
  private def repository(*args, &block)
    DataMapper.repository(*args, &block)
  end
end
