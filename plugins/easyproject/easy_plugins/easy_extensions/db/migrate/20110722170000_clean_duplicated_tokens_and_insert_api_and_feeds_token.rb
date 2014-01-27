class CleanDuplicatedTokensAndInsertApiAndFeedsToken < ActiveRecord::Migration
  def self.up
    
    tokens2del = Token.find(:all,:conditions => {:value => ''})

    token_actions = Token.all.collect(&:action).uniq

    User.all.each do |user|
      token_actions.each do |token_action|
        user_toknes = Token.find(:all, :conditions => {:user_id => user.id, :action => token_action}, :order => 'id ASC')
        if user_toknes.size > 1
          user_toknes[1..user_toknes.size].each do |t2d|
            tokens2del << t2d
          end
        end
      end
      #creating api token if not exists
      if Token.find(:all, :conditions => {:user_id => user.id, :action => 'api'}).empty?
        Token.create(:user => user, :action => 'api')
      end
      #creating feeds token if not exists
      if Token.find(:all, :conditions => {:user_id => user.id, :action => 'feeds'}).empty?
        Token.create(:user => user, :action => 'feeds')
      end
    end

    tokens2del.each{|t2d| t2d.delete}

  end

  def self.down

  end  
end
