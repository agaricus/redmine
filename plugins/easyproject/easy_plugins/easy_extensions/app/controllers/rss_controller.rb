require_dependency 'simple-rss'
require_dependency 'open-uri'
require_dependency 'net/http'
require_dependency 'net/https'
require_dependency 'timeout'

class RssController < ApplicationController

  def issues

    SimpleRSS.item_tags << :project_name
    SimpleRSS.item_tags << :link_project
    SimpleRSS.item_tags << :issue_subject
    SimpleRSS.item_tags << :link_issue
    SimpleRSS.item_tags << :issue_priority_position
    SimpleRSS.item_tags << :issue_done_ratio
    SimpleRSS.item_tags << :issue_due_date
    SimpleRSS.item_tags << :issue_status_closed
    SimpleRSS.item_tags << :link_timelog
    SimpleRSS.item_tags << :link_issues

    url, row_limit = params[:url], params[:row_limit].to_i
    my_error = test_url(url)
    if my_error == "ok"
      begin
        rss = SimpleRSS.parse(open(url))
        @rss_items = row_limit == 0 ? rss.items : rss.items[0..(row_limit-1)]
        render(:layout => !request.xhr?, :locals => {:error => nil})
      rescue
        render(:template => 'rss/bad_url', :layout => !request.xhr?, :locals => {:error => 'old_ep'})
      end
    else
      render(:template => 'rss/bad_url', :layout => !request.xhr?, :locals => {:error => my_error})
    end
  end

  def test_url(url)
    begin
      Timeout::timeout(15){
        SimpleRSS.parse(open(url))
        return "ok"
      }
    rescue Timeout::Error
      return "timeout"
    rescue
      return "bad_url"
    end
  end

end