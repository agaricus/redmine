class EasyVersionRelationsController < ApplicationController

  before_filter :find_version_by_version_id, :only => [:destroy]
  before_filter :find_relation, :only => [:destroy]

  accept_api_auth :destroy

  def destroy
    raise Unauthorized unless @relation.deletable?
    @relation.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'versions', :action => 'edit', :id => @version }
      format.js   { render(:update) {|page| page.remove "relation-#{@relation.id}"} }
      format.api  { head :ok }
    end
  end

  private

  # Find version of id params[:version_id]
  def find_version_by_version_id
    @version = Version.find(params[:version_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_relation
    @relation = EasyVersionRelation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end