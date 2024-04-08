require 'obp/access/parser'

module Obp
  module Access
    def self.start
      Obp::Access::Parser.start(options)
    end

    def self.options
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: obp-access.rb [options] URN"

        opts.on("-oOUTPUT", "--output=OUTPUT", "The output directory") do |o|
          options[:output] = o
        end
      end.parse!

      options[:urn] = ARGV.pop

      raise OptionParser::MissingArgument, 'Output folder is required. Please specify using -o or --output.' unless options[:output]
      raise OptionParser::MissingArgument, 'URN is required. Please pass it as an argument' unless options[:urn]

      options
    end
  end
end
