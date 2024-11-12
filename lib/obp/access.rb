require "obp/access/parser"
require "obp/access/converter"

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

      unless options[:output]
        raise OptionParser::MissingArgument,
              "Output folder is required. Please specify using -o or --output."
      end
      unless options[:urn]
        raise OptionParser::MissingArgument,
              "URN is required. Please pass it as an argument"
      end

      options
    end
  end
end
