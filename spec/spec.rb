require 'rails'
require 'rails/all'
require 'rspec'
require 'rspec/rails'
require 'rspec/fab'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :things do |t|
    t.string :name
    t.references :owner
  end

  create_table :owners do |t|
    t.string :name
  end
end

class Thing < ActiveRecord::Base
  belongs_to :owner
end

class Owner < ActiveRecord::Base
  has_many :things
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

describe RSpec::Fab do
  context "with prefabrication hooks" do
    before_prefabrication do
      @events ||= []
      @events << :before_prefab
    end

    after_prefabrication do
      @events ||= []
      @events << :after_prefab
    end

    fab!(:test) {
      @events ||= []
      @events << :prefab
      Thing.create(name: "thing1")
    }

    it "should trigger the prefabrication hooks in the right order" do
      expect(@events).to eq([:before_prefab, :prefab, :after_prefab])
    end
  end

  context "dependent objects" do
    fab!(:owner) {
      Owner.create(name: "owner1")
    }
    fab!(:thing) {
      Thing.create(name: "thing1", owner: owner)
    }

    it "can be created" do
      expect(thing.owner.id).to eq(owner.id)
    end
  end

  context "within a context" do
    fab!(:obj) { Thing.create }

    it "should allow direct access to prefabricated objects" do
      expect(respond_to?(:obj)).to be(true)
      expect(obj).to be_a(Thing)
    end

    it "should allow indirect access to prefabricated objects" do
      expect(Thing.count).to be(1)
      expect(Thing.first.id).to be(obj.id)
    end
  end

  context "within a different context" do
    it "should not allow access to an object from another context directly" do
      expect(respond_to?(:obj)).to be(false)
    end

    it "should not allow access to an object from another context indirectly" do
      expect(Thing.count).to be(0)
    end
  end

  context "within a parent context" do
    fab!(:parent_obj) { Thing.create }

    context "within a child context" do
      fab!(:child_obj) { Thing.create }

      it "should allow access to fabricated objects in the parent context" do
        expect(respond_to?(:parent_obj)).to be(true)
        expect(parent_obj).to be_a(Thing)
      end

      it "should allow access to fabricated objects in the child context" do
        expect(respond_to?(:child_obj)).to be(true)
        expect(child_obj).to be_a(Thing)
      end
    end

    it "should allow access to prefabricated objects in the parent" do
      expect(respond_to?(:parent_obj)).to be(true)
      expect(parent_obj).to be_a(Thing)
    end

    it "should allow indirect access to prefabricated objects in the parent" do
      expect(Thing.count).to be(1)
      expect(Thing.first.id).to be(parent_obj.id)
    end

    it "should not allow access to an object from a child context directly" do
      expect(respond_to?(:child_obj)).to be(false)
    end

    it "should not allow access to an object from a child context indirectly" do
      expect(Thing.count).to be(1)
    end
  end

  context "with multiple prefabricated objects" do
    fab!(:obj1) { Thing.create }
    fab!(:obj2) { Thing.create }

    it "should allow access to both object in the current context" do
      expect(respond_to?(:obj1)).to be(true)
      expect(obj1).to be_a(Thing)

      expect(respond_to?(:obj2)).to be(true)
      expect(obj2).to be_a(Thing)
    end
  end
end
