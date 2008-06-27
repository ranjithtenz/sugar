class UsersController < ApplicationController

    requires_authentication :except => [:login]
    
    def load_user
        @user = User.find_by_username(params[:id]) || User.find(params[:id]) rescue nil
        unless @user
            flash[:notice] = "User not found!"
            redirect_to users_url and return
        end
    end
    protected     :load_user
    before_filter :load_user, :only => [:show, :edit, :update, :destroy]
    
    def index
        @online_users = User.find_online
        @users  = User.find(:all, :order => 'username ASC', :conditions => 'activated = 1')
    end
    
    def show
        # Not much to do here
    end
    
    def edit
        require_admin_or_user(@user, :redirect => user_url(@user))
    end
    
    def update
        require_admin_or_user(@user, :redirect => user_url(@user))
        attributes = @current_user.admin? ? params[:user] : User.safe_attributes(params[:user])
        @user.update_attributes(attributes)
        if @user.valid?
            flash[:notice] = "Your changes were saved!"
            if @user == @current_user
                store_session_authentication
            end
            redirect_to user_url(:id => @user.username)
        else
            render :action => :edit
        end
    end
    
    def login
        if request.post?
            if params[:username] && params[:password]
                user = User.find_by_username(params[:username])
                if user && user.valid_password?(params[:password])
                    @current_user = user
                    store_session_authentication
                    redirect_to discussions_url and return
                end
            end
            flash.now[:notice] = "Invalid username and/or password" unless @current_user
        end
        render :layout => 'login'
    end

end
