require 'rspec/core'
require 'rspec/core/formatters/json_formatter'

module EasyExtensions
  module Tests
    module JsonFormatterSeedPatch

      def self.included(base)
        base.class_eval do

          def close_with_easy_extensions
            close_without_easy_extensions
            if output == $stdout
              output.puts
            end
          end

          alias_method_chain :close, :easy_extensions

          def seed(number)
            @output_hash[:seed] = number
          end
        end
      end

    end
  end
end

RSpec::Core::Formatters::JsonFormatter.send(:include, EasyExtensions::Tests::JsonFormatterSeedPatch)