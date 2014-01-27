require 'net/http'
require 'net/https'
require 'rubygems'
require 'active_support'

# Fork https://github.com/thoughtbot/hoptoad_notifier
module EasyExtensions

  module ExceptionsNotifier

    #    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
    #      'ActionController::RoutingError',
    #      'ActionController::InvalidAuthenticityToken',
    #      'CGI::Session::CookieStore::TamperedWithCookie',
    #      'AbstractController::ActionNotFound']

    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
      'ActionController::InvalidAuthenticityToken',
      'CGI::Session::CookieStore::TamperedWithCookie', 'Unauthorized']

    IGNORE_USER_AGENT_DEFAULT = []

    class << self
      attr_accessor :host, :port, :secure, :api_key, :http_open_timeout, :http_read_timeout,
        :proxy_host, :proxy_port, :proxy_user, :proxy_pass

      def backtrace_filters
        @backtrace_filters ||= []
      end

      # Takes a block and adds it to the list of backtrace filters. When the filters
      # run, the block will be handed each line of the backtrace and can modify
      # it as necessary. For example, by default a path matching the RAILS_ROOT
      # constant will be transformed into "[RAILS_ROOT]"
      def filter_backtrace(&block)
        self.backtrace_filters << block
      end

      # The port on which your Hoptoad server runs.
      def port
        @port || (secure ? 443 : 80)
      end

      # The host to connect to.
      def host
        @host ||= (raise ArgumentError('The host is not defined'))
      end

      # The HTTP open timeout (defaults to 2 seconds).
      def http_open_timeout
        @http_open_timeout ||= 2
      end

      # The HTTP read timeout (defaults to 5 seconds).
      def http_read_timeout
        @http_read_timeout ||= 5
      end

      # Returns the list of errors that are being ignored. The array can be appended to.
      def ignore
        @ignore ||= (EasyExtensions::ExceptionsNotifier::IGNORE_DEFAULT.dup)
        @ignore.flatten!
        @ignore
      end

      # Sets the list of ignored errors to only what is passed in here. This method
      # can be passed a single error or a list of errors.
      def ignore_only=(names)
        @ignore = [names].flatten
      end

      # Returns the list of user agents that are being ignored. The array can be appended to.
      def ignore_user_agent
        @ignore_user_agent ||= (EasyExtensions::ExceptionsNotifier::IGNORE_USER_AGENT_DEFAULT.dup)
        @ignore_user_agent.flatten!
        @ignore_user_agent
      end

      # Sets the list of ignored user agents to only what is passed in here. This method
      # can be passed a single user agent or a list of user agents.
      def ignore_user_agent_only=(names)
        @ignore_user_agent = [names].flatten
      end

      # Returns a list of parameters that should be filtered out of what is sent to Hoptoad.
      # By default, all "password" attributes will have their contents replaced.
      def params_filters
        @params_filters ||= %w(password)
      end

      def environment_filters
        @environment_filters ||= %w()
      end

      # Call this method to modify defaults in your initializers.
      #
      # EasyExtensions::ExceptionsNotifier.configure do |config|
      #   config.api_key = '1234567890abcdef'
      #   config.secure  = false
      # end
      #
      # NOTE: secure connections are not yet supported.
      def configure
        add_default_filters
        yield self
        if defined?(ActionController::Base) && !ActionController::Base.include?(EasyExtensions::ExceptionsNotifier::Catcher)
          ActionController::Base.send(:include, EasyExtensions::ExceptionsNotifier::Catcher)
        end
      end

      def protocol
        secure ? 'https' : 'http'
      end

      def url
        URI.parse("#{protocol}://#{host}:#{port}/easy_exceptions.xml")
      end

      def default_notice_options
        {
          :api_key       => EasyExtensions::ExceptionsNotifier.api_key,
          :error_message => 'Notification',
          :backtrace     => caller,
          :request       => {},
          :session       => {},
          #          :environment   => ENV.to_hash
        }
      end

      # You can send an exception manually using this method, even when you are not in a
      # controller. You can pass an exception or a hash that contains the attributes that
      # would be sent to Hoptoad:
      # * api_key: The API key for this project. The API key is a unique identifier that Hoptoad
      #   uses for identification.
      # * error_message: The error returned by the exception (or the message you want to log).
      # * backtrace: A backtrace, usually obtained with +caller+.
      # * request: The controller's request object.
      # * session: The contents of the user's session.
      # * environment: ENV merged with the contents of the request's environment.
      def notify(notice={})
        Sender.new.notify_hoptoad(notice)
      end

      def add_default_filters
        self.backtrace_filters.clear

        filter_backtrace do |line|
          line.gsub(/#{Rails.root}/, "[RAILS_ROOT]")
        end

        filter_backtrace do |line|
          line.gsub(/^\.\//, "")
        end

        filter_backtrace do |line|
          if defined?(Gem)
            Gem.path.inject(line) do |line, path|
              line.gsub(/#{path}/, "[GEM_ROOT]")
            end
          end
        end

        filter_backtrace do |line|
          line if line !~ /lib\/#{File.basename(__FILE__)}/
        end
      end
    end

    # Include this module in Controllers in which you want to be notified of errors.
    module Catcher

      def self.included(base)
        if base.instance_methods.collect(&:to_s).include?('rescue_with_handler') && !base.instance_methods.collect(&:to_s).include?('rescue_with_handler_without_easy_extensions')
          base.send(:alias_method_chain, :rescue_with_handler, :easy_extensions)
        end
      end

      def rescue_with_handler_with_easy_extensions(exception)
        notify_hoptoad(exception) unless ignore?(exception) || ignore_user_agent? || local?
        rescue_with_handler_without_easy_extensions(exception)
      end

      # This method should be used for sending manual notifications while you are still
      # inside the controller. Otherwise it works like EasyExtensions::ExceptionsNotifier.notify.
      def notify_hoptoad(hash_or_exception)
        if public_environment?
          notice = normalize_notice(hash_or_exception)
          notice = clean_notice(notice)
          send_to_hoptoad(:notice => notice)
        end
      end

      # Returns the default logger or a logger that prints to STDOUT. Necessary for manual
      # notifications outside of controllers.
      def logger
        Rails.logger
      end

      private

      def public_environment?
        defined?(Rails.env) && !['development', 'test'].include?(Rails.env)
      end

      def ignore?(exception)
        ignore_these = EasyExtensions::ExceptionsNotifier.ignore.flatten
        ignore_these.include?(exception.class) || ignore_these.include?(exception.class.name)
      end

      def local?
        return false unless request.local?
        return request.local? && !request.env.key?('X-Forwarded-For')
      end

      def ignore_user_agent?
        EasyExtensions::ExceptionsNotifier.ignore_user_agent.flatten.any?{|ua| ua === request.user_agent}
      end

      def exception_to_data(exception)
        cur_user = User.current.nil? ? '' : "##{User.current.id}:#{User.current.name} (#{User.current.mail})"
        data = {
          :api_key       => EasyExtensions::ExceptionsNotifier.api_key,
          :error_class   => exception.class.name,
          :error_message => "#{exception.class.name}: #{exception.message}",
          :backtrace     => exception.backtrace,
          #          :environment   => ENV.to_hash,
          :user          => cur_user
        }

        if self.respond_to?(:request)
          data[:request] = {
            :params      => request.parameters.to_hash,
            :rails_root  => File.expand_path(Rails.root),
            :url         => request.url
          }
          #          data[:environment].merge!(request.env.to_hash)
        end

        if self.respond_to?(:session)
          data[:session] = {
            :key         => session.instance_variable_get("@session_id"),
            :data        => session.instance_variable_get("@data")
          }
        end

        data
      end

      def normalize_notice(notice)
        case notice
        when Hash
          EasyExtensions::ExceptionsNotifier.default_notice_options.merge(notice)
        when Exception
          EasyExtensions::ExceptionsNotifier.default_notice_options.merge(exception_to_data(notice))
        end
      end

      def clean_notice(notice)
        notice[:backtrace] = clean_hoptoad_backtrace(notice[:backtrace])
        if notice[:request].is_a?(Hash) && notice[:request][:params].is_a?(Hash)
          notice[:request][:params] = filter_parameters(notice[:request][:params]) if respond_to?(:filter_parameters)
          notice[:request][:params] = clean_hoptoad_params(notice[:request][:params])
        end
        #        if notice[:environment].is_a?(Hash)
        #          notice[:environment] = filter_parameters(notice[:environment]) if respond_to?(:filter_parameters)
        #          notice[:environment] = clean_hoptoad_environment(notice[:environment])
        #        end
        clean_non_serializable_data(notice)
      end

      def send_to_hoptoad(data)
        headers = {
          'Content-type' => 'application/x-yaml',
          'Accept' => 'text/xml, application/xml',
          'csrf-param' => 'authenticity_token',
          'csrf-token' => SecureRandom.base64(32).to_s
        }

        url = EasyExtensions::ExceptionsNotifier.url

        http = Net::HTTP::Proxy(EasyExtensions::ExceptionsNotifier.proxy_host,
          EasyExtensions::ExceptionsNotifier.proxy_port,
          EasyExtensions::ExceptionsNotifier.proxy_user,
          EasyExtensions::ExceptionsNotifier.proxy_pass).new(url.host, url.port)

        http.read_timeout = EasyExtensions::ExceptionsNotifier.http_read_timeout
        http.open_timeout = EasyExtensions::ExceptionsNotifier.http_open_timeout
        if !!EasyExtensions::ExceptionsNotifier.secure
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        response = begin
          http.post(url.path, stringify_keys(data).to_yaml, headers)
        rescue TimeoutError => e
          logger.error "Timeout while contacting the Hoptoad server." if logger
          nil
        end

        case response
        when Net::HTTPSuccess
          logger.info "Hoptoad Success: #{response.class}" if logger
        else
          logger.error "Hoptoad Failure: #{response.class}\n#{response.body if response.respond_to?(:body)}" if logger
        end
      end

      def clean_hoptoad_backtrace(backtrace)
        if backtrace.to_a.size == 1
          backtrace = backtrace.to_a.first.split(/\n\s*/)
        end

        filtered = backtrace.to_a.map do |line|
          EasyExtensions::ExceptionsNotifier.backtrace_filters.inject(line) do |line, proc|
            proc.call(line)
          end
        end

        filtered.compact
      end

      def clean_hoptoad_params(params)
        params.each do |k, v|
          params[k] = "[FILTERED]" if EasyExtensions::ExceptionsNotifier.params_filters.any? do |filter|
            k.to_s.match(/#{filter}/)
          end
        end
      end

      def clean_hoptoad_environment(env)
        env.each do |k, v|
          env[k] = "[FILTERED]" if EasyExtensions::ExceptionsNotifier.environment_filters.any? do |filter|
            k.to_s.match(/#{filter}/)
          end
        end
      end

      def clean_non_serializable_data(notice)
        notice.select{|k,v| serializable?(v) }.inject({}) do |h, pair|
          h[pair.first] = pair.last.is_a?(Hash) ? clean_non_serializable_data(pair.last) : pair.last
          h
        end
      end

      def serializable?(value)
        value.is_a?(Fixnum) ||
          value.is_a?(Array)  ||
          value.is_a?(String) ||
          value.is_a?(Hash)   ||
          value.is_a?(Bignum)
      end

      def stringify_keys(hash)
        hash.inject({}) do |h, pair|
          h[pair.first.to_s] = pair.last.is_a?(Hash) ? stringify_keys(pair.last) : pair.last
          h
        end
      end

    end

    # A dummy class for sending notifications manually outside of a controller.
    class Sender
      def rescue_with_handler(exception)
      end

      include EasyExtensions::ExceptionsNotifier::Catcher
    end
  end
end
