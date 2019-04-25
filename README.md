# rspec-fab

Speed up your rails tests by safely reusing database state across a
group of tests.

## Motivation

Have you ever written a group of tests like this?

```ruby
describe SomeModel do
  let!(:instance) { SomeModel.create(params) }

  it "should ..." do
    expect(instance).to ...
  end

  it "can ..." do
    expect(instance).to ...
  end

  it "will ..." do
    expect(instance).to ...
  end

  ...
end
```

When you do this, `instance`, in this case, is created before each
example is run. This may not matter if `SomeModel` is a lightweight
object, but if it's not, creating these objects might be responsible for
the majority of the tests' execution time.

Enter `rspec-fab`. `rspec-fab` allows you to safely reuse database state
across test instances. By making a minor syntactic change, using `fab!`
instead of `let!`, you can significantly cut down your test suite
execution time.

## How does it work?

`rspec-fab` runs the code inside `fab!` blocks before the tests for a
group are run. Now, you may ask ...

---

Q: If database state is created per group, how do you prevent state from
leaking between tests?

A: `rspec-fab` is designed to be used in conjuction with the
`rspec-rails` `use_transactional_fixtures` option. This option causes
each test to run in a transaction so that each test receives the same
view of the world.

---

Q: If database state is created outside of a test and hence outside of
the test transaction, how does the state get cleaned up after the group
has completed?

A: `rspec-fab` causes each group with `fab!` invocations to run inside
a transaction so that each test is actually run inside a nested
transaction.

---

Q: My database doesn't support nested transactions, can I still use
`rspec-fab`?

A: Yes, although most relational databases don't support nested
transactions (including PostgreSQL and MySQL), ActiveRecord is able to
fake support for nested transactions using savepoints (see [here][1]).

---

Q: If objects are reused across tests, what is stopping in-memory
instance state from leaking between tests?

A: A fresh instance of each object is created when it is first used in
each test. `Model.find(id)` is used to create this new instance.


## Hooks

You might find it necessary to run code before and after the objects in
a group are constructed, but before any of the tests run. You can do this in
two ways.

If you want to apply these hooks to the whole test-suite:

```ruby
RSpec::Fab.before_prefabrication do
  ...
end

RSpec::Fab.after_prefabrication do
  ...
end
```

Or for just a particular set of tests:

```ruby
describe "..." do
  before_prefabrication do
    ...
  end

  after_prefabrication do
    ...
  end

  # The prefabrication callbacks defined above will run before and after
  # user is created.
  fab!(:user) { User.create }

  it "..." do
    expect(user).to ...
  end

  context "with condition" do
    # The prefabrication callbacks defined above will also run before
    # and after other_user is created.
    fab!(:other_user) { User.create }

    it "..." do
      expect(user).to ...
    end
  end
end
```

These callbacks are always invoked inside the group transaction.

## Installation

Just add `rspec-fab` as a dependency in your Gemfile as follows:

```ruby
group :test do
  gem 'rspec-fab'
end
```

## Settings

```ruby
RSpec.configure do |config|
  # If this is true, the first test that is run in a group receives the
  # actual object instead of a recreation. This is faster, but potentially
  # allows instance state to leak into the tests.
  config.reuse_initial_fabrication = false

  # This option makes fab! behave like let! (useful for debugging).
  config.fabricate_per_test = false
end
```

[1]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html
