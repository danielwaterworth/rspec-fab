require 'rspec'

module RSpec::Fab
  class NullHook
    def self.run(ctx); end
  end

  class Hook
    def initialize(before, after)
      @before = before
      @after = after
      @cbs = []
    end

    def add_callback(&blk)
      @cbs << blk
    end

    def run(ctx)
      @before.run(ctx)
      @cbs.each do |cb|
        ctx.instance_eval &cb
      end
      @after.run(ctx)
    end
  end

  class << self
    def before_prefabrication_hook
      @before_prefabrication_hook ||= Hook.new(NullHook, NullHook)
    end

    def after_prefabrication_hook
      @after_prefabrication_hook ||= Hook.new(NullHook, NullHook)
    end

    ##
    # Register a callback to run before fabrication for all tests

    def before_prefabrication(&blk)
      before_prefabrication_hook.add_callback(&blk)
    end

    ##
    # Register a callback to run before fabrication for all tests

    def after_prefabrication(&blk)
      after_prefabrication_hook.add_callback(&blk)
    end
  end

  module ExtensionModule
    def before_prefabrication_hook
      @before_prefabrication_hook ||= begin
        parent_hook =
          if self.parent.respond_to?(:before_prefabrication_hook)
            self.parent.before_prefabrication_hook
          else
            RSpec::Fab.before_prefabrication_hook
          end
        RSpec::Fab::Hook.new(parent_hook, RSpec::Fab::NullHook)
      end
    end

    def after_prefabrication_hook
      @after_prefabrication_hook ||= begin
        parent_hook =
          if self.parent.respond_to?(:after_prefabrication_hook)
            self.parent.after_prefabrication_hook
          else
            RSpec::Fab.after_prefabrication_hook
          end
        RSpec::Fab::Hook.new(RSpec::Fab::NullHook, parent_hook)
      end
    end

    ##
    # Register a callback to run before fabrication for all tests in this
    # context and descendents

    def before_prefabrication(&blk)
      before_prefabrication_hook.add_callback(&blk)
    end

    ##
    # Register a callback to run after fabrication for all tests in this
    # context and descendents

    def after_prefabrication(&blk)
      after_prefabrication_hook.add_callback(&blk)
    end

    def setup_prefabrication
      @prefabricated_things = {}
      @prefabricated_descriptors = []
      @prefabricated_classes = {}
      @prefabricated_ids = {}

      prefabricated_things = @prefabricated_things
      prefabricated_descriptors = @prefabricated_descriptors
      prefabricated_classes = @prefabricated_classes
      prefabricated_ids = @prefabricated_ids

      before(:each) do
        prefabricated_things.clear
      end

      this = self

      before(:all) do
        ActiveRecord::Base.connection.begin_transaction(joinable: false)

        this.before_prefabrication_hook.run(self)

        prefabricated_descriptors.each do |name, generator|
          thing = instance_eval &generator
          prefabricated_classes[name] = thing.class
          prefabricated_ids[name] = thing.id

          if RSpec.configuration.reuse_initial_fabrication?
            prefabricated_things[name] = thing
          end
        end

        this.after_prefabrication_hook.run(self)
      end

      after(:all) do
        ActiveRecord::Base.connection.rollback_transaction
      end
    end

    ##
    # Declare a new fabricated thing to be accessible in tests within this
    # context and its descendents. For example:
    #
    #   fab!(:user) { User.create }
    #

    def fab!(name, &blk)
      if RSpec.configuration.fabricate_per_test?
        let!(name, &blk)
      else
        setup_prefabrication unless @prefabricated_things

        @prefabricated_descriptors << [name, blk]
        prefabricated_things = @prefabricated_things
        prefabricated_classes = @prefabricated_classes
        prefabricated_ids = @prefabricated_ids

        define_method(name) do
          prefabricated_things[name] ||= prefabricated_classes[name].find(prefabricated_ids[name])
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.extend RSpec::Fab::ExtensionModule

  config.add_setting :reuse_initial_fabrication, default: false
  config.add_setting :fabricate_per_test, default: false
end
