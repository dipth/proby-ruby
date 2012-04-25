# -*- encoding: utf-8 -*-
require File.expand_path("../lib/proby/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "proby"
  s.license     = "MIT"
  s.version     = Proby::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John Wood", "Doug Barth"]
  s.email       = ["john@signalhq.com", "doug@signalhq.com"]
  s.homepage    = "http://github.com/signal/proby-ruby"
  s.summary     = %Q{A simple library for working with the Proby task monitoring application.}
  s.description = %Q{A simple library for working with the Proby task monitoring application.}

  s.rubyforge_project = "proby"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rake", "~> 0.9.0"
  s.add_development_dependency "yard", "~> 0.6.4"
  s.add_development_dependency "bluecloth", "~> 2.1.0"
  s.add_development_dependency "fakeweb", "~> 1.3.0"
  s.add_development_dependency "shoulda", "~> 2.11.3"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end

