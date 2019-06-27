module T
  def self.any(type_a, type_b, *types); end
  def self.nilable(type); end
  def self.untyped; end
  def self.noreturn; end
  def self.all(type_a, type_b, *types); end
  def self.enum(values); end
  def self.proc; end
  def self.self_type; end
  def self.class_of(klass); end
  def self.type_alias(type); end
  def self.type_parameter(name); end

  def self.cast(value, type, checked: true); value; end
  def self.let(value, type, checked: true); value; end
  def self.assert_type!(value, type, checked: true); value; end
  def self.unsafe(value); value; end
  def self.must(arg, msg=nil); arg; end
  def self.reveal_type(value); value; end
end

class T::Struct
  def initialize(vals)
    vals.each do |key, val|
      instance_variable_set(:"@#{key}", val)
    end
  end

  def self.const(name, cls, rules={})
    if rules.key?(:immutable)
      raise ArgumentError.new("Cannot pass 'immutable' argument when using 'const' keyword to define a prop")
    end
  
    self.prop(name, cls, rules.merge(immutable: true))
  end

  def self.prop(name, cls, rules={})
    if rules[:immutable]
      send(:define_method, "#{name}=") do |_|
        raise "#{name} cannot be modified after creation."
      end
    else
      send(:define_method, "#{name}=") do |x|
        instance_variable_set(:"@#{name}", x)
      end
    end

    send(:define_method, name) do
      instance_variable_get(:"@#{name}")
    end
  end
end

module T::Helpers
  def interface!; end
  def abstract!; end
end

module T::Sig
  def sig(&blk); end
end

module T::Array
  def self.[](type); end
end

module T::Hash
  def self.[](keys, values); end
end

module T::Enumerable
  def self.[](type); end
end

module T::Range
  def self.[](type); end
end

module T::Set
  def self.[](type); end
end

module T::Boolean
end
