module EasyPatch
  module DocumentsHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def documents_to_csv(documents, query)
          encoding = l(:general_csv_encoding)
          export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
            # csv header fields
            headers = Array.new
            query.columns.each do |c|
              headers << c.caption
            end
            headers << l(:field_filename)
            headers << l(:field_author)
            headers << "#{l(:field_filename)} #{l(:field_created_on).downcase}"
            csv << headers.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
            # csv lines
            documents.each do |entity|
              entity.attachments.each do |file|
                fields = Array.new
                query.columns.each do |column|
                  fields << format_value_for_export(entity, column)
                end
                fields << file.filename
                fields << file.author.name
                fields << format_time(file.created_on)
                csv << fields.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
              end
            end
          end

          export
        end

      end

    end

    module InstanceMethods
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'DocumentsHelper', 'EasyPatch::DocumentsHelperPatch'
