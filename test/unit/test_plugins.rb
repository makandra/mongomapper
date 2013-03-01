require 'test_helper'

module MyPlugin
  def self.configure(model)
    model.class_eval { attr_accessor :from_configure }
  end

  module ClassMethods
    def class_foo
      'class_foo'
    end
  end

  module InstanceMethods
    def instance_foo
      'instance_foo'
    end
  end
end

class PluginsTest < Test::Unit::TestCase
  context "plugin" do
    setup do
      @document = Class.new do
        extend MongoMapper::Plugins
        plugin MyPlugin
      end
    end

    should "include instance methods" do
      @document.new.instance_foo.should == 'instance_foo'
    end

    should "extend class methods" do
      @document.class_foo.should == 'class_foo'
    end

    should "pass model to configure" do
      @document.new.should respond_to(:from_configure)
    end

    should "default plugins to empty array" do
      Class.new { extend MongoMapper::Plugins }.plugins.should == []
    end

    should "add plugin to plugins" do
      @document.plugins.should include(MyPlugin)
    end
  end

  context ".plugin (when Object has ClassMethods or InstanceMethods)" do
    setup do
      # Sanity check that there are no ClassMethods or InstanceMethods modules around
      ::Object.const_defined?(:ClassMethods).should be_false
      ::Object.const_defined?(:InstanceMethods).should be_false

      class ::Object
        module ClassMethods; end
        module InstanceMethods; end
      end

      module MyOtherPlugin
        def self.configure(model)
          model.class_eval { attr_accessor :from_configure }
        end
      end
    end

    teardown do
      ::Object.class_eval do
        remove_const :ClassMethods
        remove_const :InstanceMethods
      end
    end

    should "not try to load methods from ancestors (relevant for Ruby 1.9+)" do
      # This can break horribly:
      # https://makandracards.com/makandra/14699-module-const_defined-behaves-differently-in-ruby-1-9-and-ruby-1-8

      my_class = Class.new
      loading_plugins = lambda do
        my_class.class_eval do
          extend MongoMapper::Plugins
          plugin MyOtherPlugin
        end
      end

      loading_plugins.should_not raise_error # Will happen if ClassMethods/InstanceMethods is resolved incorrectly.

      my_class.should_not respond_to(:class_foo)
      my_class.new.should_not respond_to(:instance_foo)
    end
  end
end
