require 'open3'

module EasyExtensions
  module Tests

    class RakeTestParser
      
      attr_reader :rakes
      
      def initialize(rakes=[], parser = nil)
        @rakes = rakes.collect{|rake| RakeRunner.new(rake, parser) }
        @all_done = false
      end

      def add_rake(rake, parser=nil)
        @rakes << RakeRunner.new(rake, parser)
        @all_done = false
        true
      end
      
      def run_all
        @rakes.each do |rake|
          unless rake.done?
            puts 'Running rake ' + rake.rake + ' at ' + Time.now.strftime('%F %H:%M')
            rake.run
            puts 'Done.'
          end
        end
        @all_done = true
      end

      def report
        ensure_parsed
        @rakes.collect{|rake| rake.result.to_s }
      end

      def get_results
        ensure_parsed
        @rakes.collect{|rake| rake.result }
      end

      private

      def ensure_parsed
        raise StandardError.new('Not parsed! call run_all first') unless @all_done
      end

    end

    class RakeRunner
      attr_reader :result, :rake

      def done?
        @done
      end

      def initialize(rake, parser=nil)
        @rake = rake
        @parser = parser
        @done = false
      end

      def run
        buffer = []
        stdout_str, stderr_str, status = Open3::capture3('rake ' +@rake)
        
        stdout_str.split("\n").each do |line|
          buffer << line
        end

        empty = !buffer.any?
        stderr_str.split("\n").each do |line|
          buffer << line if empty
          $stderr.puts line
        end
        
        buffer.each{|line| line.strip! }

        @result = EasyExtensions::Tests::ParsedTestResult.new(@rake, buffer, @parser)
        @done = true
        @result
      end
    end
    
    class ParsedTestResult
      class NotYetParsedError < StandardError
      end

      PARSERS = {
        'standard' => 'EasyExtensions::Tests::StandartRailsTestParser',
        'rspec_json' => 'EasyExtensions::Tests::JsonRspecTestParser'
      }
      
      attr_reader :rake, :parsed

      [:failured, :failure_abbr, :time_result, :text_result].each do |method|
        src = <<-END_SRC
        def #{method}
          raise NotYetParsedError('Result is not parsed!') unless parsed?
          @output_parser.#{method}
        end
        END_SRC
        self.class_eval(src, __FILE__, __LINE__)
      end
      
      def parsed?
        !!@parsed
      end
      
      def initialize(rake, output=[], parser = nil)
        @rake, @output, @parsed = rake, output, false

        @parser = parser
        
        parse_output
      end
      
      def all_ok?
        @parsed && @output_parser.failured.size == 0
      end

      def to_s
        s = "#{rake} run, time info: #{@output_parser.time_result} and reported #{@output_parser.text_result}"
        unless all_ok?
          s << " errors:\n" + @output_parser.failured.collect{|fail| fail.to_s }.join("\n")
        end
        s
      end
      
      private
      
      def parse_output
        @output_parser = instantialize_parser
        @parsed = @output_parser.parse
      end

      def instantialize_parser
        parser = begin PARSERS[@parser||'standard'].constantize rescue StandartRailsTestParser end
        return parser.new(@output)
      end
      
    end

    class AbstractTestOutputParser
      attr_reader :failured, :failure_abbr, :time_result, :text_result

      class AbstractParsedFailure
        attr_reader :type, :test_name, :test_set, :file, :file_line

        def initialize(type)
          @type = type
          @initialized = false
          @additional_info ||= []
          @time_result ||= ''
          @info ||= ''
        end

        def heading
          s = "Test #{test_name} in test set #{test_set} "
          unless error?
            s << "in test file #{file} on line #{file_line} has failed!"
          else
            s << 'raised an error!'
          end
          s
        end

        def main_info
          @info
        end

        def info(join="\n")
          ([main_info]+@additional_info).join(join)
        end

        def to_s
          heading + info
        end

        def error?
          type == 'Error'
        end
      end #AbstractParsedFailure

      def initialize(output=[])
        @output = output
        @failured = []
        @failure_abbr, @time_result, @text_result = '', '', ''
      end

      def parse
        raise NotImplementedError, 'child responsibility'
      end

    end

    class StandartRailsTestParser < AbstractTestOutputParser

      class ParsedFilure < AbstractTestOutputParser::AbstractParsedFailure
        
        # adds a line of output to this failure
        def <<(line)
          if !@initialized && m = line.match(init_regex)
            @test_name = m[1]
            @test_set = m[2]
            #if error theese are nil
            @file = m[3]
            @file_line = m[4]
            @initialized = true
            return
          end
          return unless @initialized
          unless @info
            @info = line
          else
            @additional_info << line
          end
        end

        private

        def init_regex
          if error?
            /^(\S+)\((\S+)\).*$/
          else
            /^(\S+)\((\S+)\)\s\[([^:]*):(\d+)\].*$/
          end
        end

      end #ParsedFailure

      def parse
        return false if !@output.is_a?(Array)

        idx = -1

        while idx < @output.count && ( @failure_abbr.blank? || @time_result.blank? )
          idx += 1
          # should match time result too, but what if it will change?...
          if @output[idx] =~ /^[F.*]+$/
            @failure_abbr = @output[idx]
            idx += 2
            @time_result = @output[idx]
          end
        end

        return false if @failure_abbr.blank? || @time_result.blank?
        
        
        while idx < @output.size
          idx += 1
          line = @output[idx]

          if line =~ /^\s*$/
            actual_failure = nil
            next
          end

          if line =~ /^\s*\d+\)\s*(\w+):/
            actual_failure = ParsedFilure.new($1)
            failured << actual_failure
          end

          next unless actual_failure

          actual_failure << line
        end

        @text_result = @output.last
        if @text_result =~ /^ruby/
          @text_result = @output[-3]
        end

        return true
      end

    end # StandartRailsTestParser

    class JsonRspecTestParser < AbstractTestOutputParser

      class ParsedFilure < AbstractTestOutputParser::AbstractParsedFailure
        def initialize(example_hash)
          @test_name = example_hash['full_description']
          @test_set = example_hash['full_description'].split(/\s/).first
          #if error theese are nil
          @file = example_hash['file_path']
          @file_line = example_hash['line_number']

          @info = example_hash['exception']['message'] if example_hash['exception']
          @additional_info = example_hash['exception']['backtrace']

          @exception_type = example_hash['exception']['class']
          super( error? ? 'Error' : 'Failure')
          @initialized = true
        end

        def error?
          @exception_type != "RSpec::Expectations::ExpectationNotMetError"
        end
      end

      def parse
        result = nil
        @output.each do |line|
          if line =~ /(\{.*\})[^}]*\Z/
            begin
              result = JSON.parse($1)
            rescue
              #maybe report it to the additional info
              $stderr.puts "JSON tried out to parse a line: \"#{line}\""
            end
          end
        end
        @time_result = result['summary']['duration']
        @text_result = result['summary_line'] + ' seed: ' + result['seed'].to_s
        result['examples'].each do |example|
          next if example['status'] == 'passed' || example['status'] == "pending"
          failured << ParsedFilure.new(example)
        end
      end

    end

  end
end
