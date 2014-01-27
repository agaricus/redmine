require 'rubygems'
require 'active_resource'

module EasyExtensions
  module Tests
    # Issue model on the client side
    class Issue < ActiveResource::Base
      class << self
        attr_reader :api_key

        def api_key=(key)
          @api_key = key
          self.headers["X-Redmine-API-Key"] = key
        end
      end

    end


    class TestReporter

      class << self
        attr_reader :default_api_key
      end

      def initialize(server, issue_id, api_key=nil)
        EasyExtensions::Tests::Issue.site = server
        EasyExtensions::Tests::Issue.api_key = api_key || self.class.default_api_key
        @issue = EasyExtensions::Tests::Issue.find(issue_id)
      rescue ActiveResource::ResourceNotFound => e
        $stderr.puts "ActiveResource was not able to find a Issue id #{issue_id} on server #{server} with key #{api_key}"
        raise e
      end

      def report(parser)
        results = parser.get_results

        if Rails.root.to_s =~ /\/([^\/]+)\/public_html/
          folder = $1
        else
          folder = Rails.root
        end

        info = '<div>'
        info << "<h2>#{folder}</h2>"
        info << "<strong>Informations: </strong>"
        info << '<ul>'
        info << "<li><strong>Git-branch:</strong> #{%x(git rev-parse --abbrev-ref HEAD)}</li>"
        info << "<li><strong>Database driver:</strong> #{Rails.configuration.database_configuration[Rails.env]['adapter']}</li>"
        info << "<li><strong>Folder:</strong> #{Rails.root}</li>"
        info << '</ul>'
        info << '</div>'

        report_details = [info] + results.collect do |result|
          details = '<div>'
          details << "<h4>Rake #{result.rake} summary</h4><pre>#{ERB::Util.h(result.time_result)}<br>#{ERB::Util.h(result.text_result)}</pre>"
          if result.all_ok?
            details << 'Reports OK'
          else
            details << '<div class="module-toggle-button manual"><div class="group"><span class="expander">&nbsp;</span><h3 class="module-heading">Failures</h3></div></div>'
            details << '<div style="display:none;">'
            result.failured.each do |failure|
              details << "<p><h4>#{failure.heading}</h4><pre>#{ERB::Util.h(failure.info)}</pre></p>"
            end
            details << '</div>'
          end
          details << '</div>'
          details
        end

        @issue.notes = report_details.join("\n")
        @issue.save
      end

    end # TestReporter

  end
end
