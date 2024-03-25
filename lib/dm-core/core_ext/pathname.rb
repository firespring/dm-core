class Pathname
  # alias_method :to_s, :to to_str when to_str not defined
  alias_method :to_str, :to_s unless public_instance_methods(false).any? { |m| m.to_sym == :to_str }
end
