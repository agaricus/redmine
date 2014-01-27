require 'easy_extensions/easy_scheduler'

module EasyExtensions

  class EasyProjectPageHeater
    include ActionController::TestProcess

    attr_accessor :epph_action, :epph_parameters, :epph_session, :epph_flash

    def initialize(action, parameters = nil, session = nil, flash = nil)
      self.epph_action, self.epph_parameters, self.epph_session, self.epph_flash = action, parameters, session, flash
    end

    def self.logger
      Rails.logger
    end

    def logger
      self.class.logger
    end

    def reset_variables
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
      @controller = ProjectsController.new
    end

    def hit_page
      raise NotImplementedError, 'You have to override this method.'
    end

    protected

    def hit_page_with_get
      get(self.epph_action, self.epph_parameters, self.epph_session, self.epph_flash)
    end

  end

  class EasyProjectHeaterSchedulerTask < EasyExtensions::EasySchedulerTask
    include ActionController::TestProcess

    def initialize(options={})
      super('easy_project_heater_scheduler_task', options)
    end

    def execute
      logger.info 'EasyProjectHeaterSchedulerTask excuting...' if logger
      FileUtils.rm Dir[ActionController::Base.cache_store.cache_path + '/views/*.cache']

      @@page_heaters.each do |page_heater|
        logger.info "EasyProjectHeaterSchedulerTask excuting #{page_heater.class.name}..." if logger
        page_heater.hit_page
        logger.info "EasyProjectHeaterSchedulerTask excuted #{page_heater.class.name}." if logger
      end unless @@page_heaters.blank?

      logger.info 'EasyProjectHeaterSchedulerTask excuted.' if logger
    end

    class << self

      @@page_heaters = []

      def map
        yield self if block_given?
      end

      def add_page_heater(page_heater)
        return unless page_heater.is_a?(EasyExtensions::EasyProjectPageHeater)
        @@page_heaters << page_heater
      end

      def page_heaters
        @@page_heaters
      end

    end

  end

end