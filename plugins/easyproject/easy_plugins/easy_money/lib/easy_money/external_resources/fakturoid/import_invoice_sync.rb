require 'easy_extensions/external_resources/fakturoid/fakturoid_import_sync_base'
require 'easy_money/external_resources/fakturoid/invoice'

module EasyMoney
  class ExternalResources::Fakturoid::ImportInvoiceSync < EasyExtensions::ExternalResources::Fakturoid::FakturoidImportSyncBase

    class << self

      def internal_entity_class
        ::EasyMoneyOtherRevenue
      end

      def external_entity_class
        ::EasyMoney::ExternalResources::Fakturoid::Invoice
      end

    end

    protected

    def update_entity_without_save(current_entity, external_resource)
      current_entity.spent_on = begin; Date.parse(external_resource.issued_on); rescue; Date.today; end
      current_entity.name = external_resource.number

      desc = '<p>'
      desc << external_resource.html_url
      desc << '<br />'

      unless external_resource.lines.blank?
        desc << '<table>'
        external_resource.lines.each do |line|
          desc << '<tr>'
          desc << "<td>#{line.quantity}</td>"
          desc << "<td>#{line.unit_name}</td>"
          desc << "<td>#{line.name}</td>"
          desc << "<td>#{line.vat_rate}</td>"
          desc << "<td>#{line.unit_price}</td>"
          desc << "<td>#{(line.unit_price.to_f * line.quantity.to_f).round(2)}</td>"
          desc << '</tr>'
        end
        desc << '</table>'
      end
      desc << '</p>'

      current_entity.description = desc
      current_entity.price1 = begin; BigDecimal.new(external_resource.native_total); rescue; external_resource.native_total; end
      current_entity.price2 = begin; BigDecimal.new(external_resource.native_subtotal); rescue; external_resource.native_subtotal; end
      if current_entity.price1.is_a?(BigDecimal) && current_entity.price2.is_a?(BigDecimal) && current_entity.price2 > 0.0
        begin
          current_entity.vat = ((current_entity.price1 / current_entity.price2 * 100) - 100).round(2)
        rescue
        end
      end
      current_entity.easy_external_id = external_resource.id
    end

  end
end
