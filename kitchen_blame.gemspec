# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen_blame/version'

Gem::Specification.new do |spec|
  spec.name          = 'kitchen_blame'
  spec.version       = KitchenBlame::VERSION
  spec.authors       = ["Brian O'Connell"]
  spec.email         = ['boc [at] us.ibm.com']

  spec.summary       = 'Analyzes Test Kitchen logs to assist in optimizations.'
  spec.description   = 'Analyzes Test Kitchen logs to help optimize boot times, recipes, and individual resources.'
  spec.homepage      = "https://github.com/boc-tothefuture/kitchen-blame"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_dependency 'thor'
end
