# frozen_string_literal: true

require 'bundler'

Bundler.require

module QA
  Error = Class.new(StandardError)
end

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__, namespace: QA)
loader.ignore("#{__dir__}/spec")
loader.setup
