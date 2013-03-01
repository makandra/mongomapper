# encoding: UTF-8
module MongoMapper
  module Plugins
    def plugins
      @plugins ||= []
    end

    def plugin(mod)
      debugger if mod.respond_to? :debug_me
      extend mod::ClassMethods     if const_defined_in?(:ClassMethods, mod)
      include mod::InstanceMethods if const_defined_in?(:InstanceMethods, mod)
      mod.configure(self)          if mod.respond_to?(:configure)
      plugins << mod
    end

    def const_defined_in?(name, mod)
      if mod.method(:const_defined?).arity == 1 # Ruby 1.8
        mod.const_defined?(name)
      else
        mod.const_defined?(name, false)
      end
    end
  end
end
