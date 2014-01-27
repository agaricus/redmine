
module EasyExtensions

  class EntityRepeater

    def entity
      @entity.constantize
    end

    @@available = []

    def initialize(entity_string, options={})
      @entity = entity_string
    end

    def entities_to_repeat
      entity.easy_to_repeat
    end

    #should be used only for conditions which can not be handled easily in entities_to_repeat
    def skip_entity?(entity)
      false
    end

    class << self

      def map
        yield self
      end

      def register(*args)
        easy_repeater = args.first
        unless easy_repeater.is_a?(EasyExtensions::EntityRepeater)
          easy_repeater = EasyExtensions::EntityRepeater.new(*args)
        end
        @@available << easy_repeater
      end

      def all_repeaters
        @@available
      end
    end

  end


  class IssueRepeater < EntityRepeater

    def initialize
      super('Issue')
    end

    def entities_to_repeat
      scope = Issue.easy_to_repeat.joins(:project)
      scope = scope.where( "#{Project.table_name}" => { :easy_is_easy_template => false, :status => Project::STATUS_ACTIVE })
      scope = scope.includes( :project )
    end

    def skip_enity?(entity)
      entity.project.due_date && entity.project.due_date <= Date.today
    end

  end

end
