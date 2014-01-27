class EasyProjectRelationsController < ApplicationController

  before_filter :find_project_by_project_id, :only => [:destroy]
  before_filter :find_relation, :only => [:destroy]

  accept_api_auth :destroy

  def destroy
    raise Unauthorized unless @relation.deletable?
    @relation.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project }
      format.js   { render(:update) {|page| page.remove "relation-#{@relation.id}"} }
      format.api  { head :ok }
    end
  end

  private

  def find_relation
    @relation = EasyProjectRelation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end