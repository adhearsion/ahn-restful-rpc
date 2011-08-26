GEM_FILES = %w{
  lib/ahn-restful-rpc.rb
  config/ahn-restful-rpc.yml
}

Gem::Specification.new do |s|
  s.name = "ahn-restful-rpc"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jay Phillips"]

  s.date = Date.today.to_s
  s.description = "Allows remote procedure calls over an HTTP API integrated in Adhearsion"
  s.email = "dev&adhearsion.com"

  s.files = GEM_FILES

  s.has_rdoc = false
  s.homepage = "https://github.com/adhearsion/ahn-restful-rpc"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.2.0"
  s.summary = "Provides a RESTful RPC API on Adhearsion"

  s.specification_version = 2

  s.add_dependency "adhearsion"
  s.add_dependency "json"
  s.add_dependency "rack"
  s.add_development_dependency "rspec"
end
