module EasyUtils
  class ShellUtils

    class CommandFailed < StandardError #:nodoc:
    end

    def self.logger
      Rails.logger
    end

    def self.shell_quote(str)
      if Redmine::Platform.mswin?
        '"' + str.gsub(/"/, '\\"') + '"'
      else
        "'" + str.gsub(/'/, "'\"'\"'") + "'"
      end
    end

    def self.stderr_log_file
      if @stderr_log_file.nil?
        writable = false
        path = Redmine::Configuration['scm_stderr_log_file'].presence
        path ||= Rails.root.join("log/#{Rails.env}.scm.stderr.log").to_s
        if File.exists?(path)
          if File.file?(path) && File.writable?(path)
            writable = true
          else
            logger.warn("SCM log file (#{path}) is not writable")
          end
        else
          begin
            File.open(path, "w") {}
            writable = true
          rescue => e
            logger.warn("SCM log file (#{path}) cannot be created: #{e.message}")
          end
        end
        @stderr_log_file = writable ? path : false
      end
      @stderr_log_file || nil
    end

    def self.shellout(cmd, options = {}, &block)
      if logger && logger.debug?
        logger.debug "Shelling out: #{cmd}"
        # Capture stderr in a log file
        if stderr_log_file
          cmd = "#{cmd} 2>>#{shell_quote(stderr_log_file)}"
        end
      end
      begin
        mode = "r+"
        IO.popen(cmd, mode) do |io|
          io.set_encoding("ASCII-8BIT") if io.respond_to?(:set_encoding)
          io.close_write unless options[:write_stdin]
          block.call(io) if block_given?
        end
        ## If scm command does not exist,
        ## Linux JRuby 1.6.2 (ruby-1.8.7-p330) raises java.io.IOException
        ## in production environment.
        # rescue Errno::ENOENT => e
      rescue Exception => e
        msg = e.message
        # The command failed, log it and re-raise
        logmsg = "Command failed. "
        logmsg += "#{cmd}\n"
        logmsg += "with: #{msg}"
        logger.error(logmsg)
        raise CommandFailed.new(msg)
      end
    end
  end
end
