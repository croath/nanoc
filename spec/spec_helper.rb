require 'simplecov'
SimpleCov.start

require 'nanoc'
require 'nanoc/cli'

# FIXME: This should not be necessary (breaks SimpleCov)
module Nanoc::CLI
  def self.setup_cleaning_streams
  end
end

Nanoc::CLI.setup

RSpec.configure do |c|
  c.around(:each) do |example|
    Nanoc::CLI::ErrorHandler.disable
    example.run
    Nanoc::CLI::ErrorHandler.enable
  end

  c.around(:each) do |example|
    Dir.mktmpdir('nanoc-test') do |dir|
      FileUtils.cd(dir) do
        example.run
      end
    end
  end

  c.before(:each, site: true) do
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('layouts')
    FileUtils.mkdir_p('lib')
    FileUtils.mkdir_p('output')

    File.write('nanoc.yaml', '{}')

    File.write('Rules', 'passthrough "/**/*"')
  end
end

RSpec::Matchers.define :raise_frozen_error do |_expected|
  match do |actual|
    begin
      actual.call
      false
    rescue => e
      if e.is_a?(RuntimeError) || e.is_a?(TypeError)
        e.message =~ /(^can't modify frozen |^unable to modify frozen object$)/
      else
        false
      end
    end
  end

  supports_block_expectations

  failure_message do |_actual|
    'expected that proc would raise a frozen error'
  end

  failure_message_when_negated do |_actual|
    'expected that proc would not raise a frozen error'
  end
end
