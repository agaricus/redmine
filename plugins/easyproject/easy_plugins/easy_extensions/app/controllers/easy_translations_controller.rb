class EasyTranslationsController < ApplicationController
  before_filter :require_admin

  before_filter :find_entity, :except => [:destroy]
  before_filter :cached_languages, :only => [:index, :create]

  def index

    @translations = @entity.easy_translations.where(:entity_column => @entity_column)
    @available_locales = @translated_langs_from_cache.keys - @translations.pluck(:lang)

    respond_to do |format|
      format.js
    end
  end

  def update
    @easy_translations_attributes = params[:easy_translations]
    if @easy_translations_attributes
      @entity.send("easy_translated_#{@entity_column}=", {nil => @easy_translations_attributes[:original_value]})
      unless @entity.save
        flash[:error] = @entity.errors.full_messages
        return redirect_back_or_default(@entity)
      end
      EasyTranslation.transaction do
        @entity.easy_translations.all.each do |t|
          t.update_attributes(:value => @easy_translations_attributes[t.id.to_s]) if @easy_translations_attributes[t.id.to_s]
        end
      end
    end
    respond_to do |format|
      format.html {redirect_back_or_default(@entity)}
    end
  end

  def create
    @easy_translation = @entity.easy_translations.create!(:entity_column => @entity_column, :lang => params[:lang], :value => @entity.send(@entity_column))
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @easy_translation = EasyTranslation.find(params[:id])
    @easy_translation.destroy
    respond_to do |format|
      format.js
    end
  end

  private

  def find_entity
    @entity = params[:entity_type].camelcase.constantize.find(params[:entity_id])
    @entity_column = @entity.class.translater_options[:columns].detect{|i| i.to_s == params[:entity_column]}
  end

  def cached_languages
    @translated_langs_from_cache = languages_options.inject({}){|mem,var| mem[var.last.to_s] = var.first; mem}
  end
end
