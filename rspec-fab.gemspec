# frozen_string_literal: true
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name = "rspec-fab"
  gem.version = "0.1.0"
  gem.authors = ["Daniel Waterworth"]
  gem.email = ["me@danielwaterworth.com"]
  gem.description = <<-EOF
  EOF
  gem.summary = ""
  gem.license = "MIT"
  gem.require_paths = ["lib"]
  gem.files = `git ls-files -- lib/*`.split("\n")
  gem.files += ['README.md', 'LICENSE']
  gem.extra_rdoc_files = ['README.md']
  gem.add_runtime_dependency "rspec", [">= 3.0.0", "< 4.0.0"]
  gem.add_runtime_dependency "rspec-rails", [">= 3.0.0", "< 4.0.0"]
  gem.add_runtime_dependency "activerecord", [">= 4.0.0", "< 7.0.0"]
end
