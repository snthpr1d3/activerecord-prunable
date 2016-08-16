Gem::Specification.new do |spec|
  spec.name          = "activerecord-prunable"
  spec.version       = "0.2.0"
  spec.authors       = ["dr2m"]
  spec.email         = ["maletin@maletin.work"]

  spec.summary       = "Convenient removal of obsolete ActiveRecord models."
  spec.license       = "MIT"

  spec.files         = Dir.glob('**/*').reject{|f| f.match(%r{^(spec)/}) }

  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "activerecord"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "byebug"
end
