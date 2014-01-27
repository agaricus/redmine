module EasyExtensions
  module CustomFields

    class EasyRatingCustomFieldFormat < Redmine::CustomFieldFormat
    
      def initialize(options={})
        super('easy_rating', options)
      end

      def format_as_easy_rating(value)
        "#{value}%"
      end
    end

  end
end