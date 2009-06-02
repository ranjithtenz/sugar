class DiscussionsController < ApplicationController
    
    requires_authentication
    
    def load_discussion
        @discussion = Discussion.find(params[:id]) rescue nil
        unless @discussion
            flash[:notice] = "Could not find that discussion!"
            redirect_to discussions_path and return
        end
        unless @discussion.viewable_by?(@current_user)
            flash[:notice] = "You don't have permission to view that discussion!"
            redirect_to discussions_path and return
        end
    end
    protected     :load_discussion
    before_filter :load_discussion, :only => [:show, :edit, :update, :destroy, :follow, :unfollow, :favorite, :unfavorite]

    def verify_editable
        unless @discussion.editable_by?(@current_user)
            flash[:notice] = "You don't have permission to edit that discussion!"
            redirect_to discussions_path and return
        end
    end
    protected     :verify_editable
    before_filter :verify_editable, :only => [:edit, :update, :destroy]
    
    def load_categories
        @categories = Category.find(:all).reject{|c| c.trusted? unless (@current_user.trusted? || @current_user.admin?) }
    end
    before_filter :load_categories, :only => [:new, :create, :edit, :update]

    def index
        @discussions = Discussion.find_paginated(:page => params[:page], :trusted => @current_user.trusted?)
        find_discussion_views
    end
    
    def search
        if params[:q]
            redirect_to( { :action => :search, :query => params[:q] } ) and return
        end
        unless @search_query = params[:query]
            flash[:notice] = "No query specified!"
            redirect_to discussions_path and return
        end
        start_time = Time.now
        @discussions = Discussion.search_paginated(:page => params[:page], :trusted => @current_user.trusted?, :query => @search_query)
        find_discussion_views
        @search_time = Time.now - start_time
    end
    
    def new
        @discussion = @current_user.discussions.new
    end
    
    def show
		context = 0
		respond_to do |format|
			format.html do
				context = 3
			end
			format.iphone do
			end
		end
        @posts = Post.find_paginated(:page => params[:page], :discussion => @discussion, :context => context)
        last_index = @posts.offset + @posts.length
        if discussion_view = DiscussionView.find(:first, :conditions => ['user_id = ? AND discussion_id = ?', @current_user.id, @discussion.id])
            discussion_view.update_attributes(:post_index => last_index, :post_id => @posts.last.id) if discussion_view.post_index < last_index
        else
            DiscussionView.create(:discussion_id => @discussion.id, :user_id => @current_user.id, :post_index => last_index, :post_id => @posts.last.id)
        end
    end
    
    def edit
        @discussion.body = @discussion.posts.first.body
    end
    
    def create
        attributes = @current_user.moderator? ? params[:discussion] : Discussion.safe_attributes(params[:discussion])
        @discussion = @current_user.discussions.create(attributes)
        @discussion.update_attributes(attributes.merge(:new_closer => @current_user))
        if @discussion.valid?
            redirect_to discussion_path(@discussion) and return
        else
            flash.now[:notice] = "Could not save your discussion, did you fill in all required fields?"
            render :action => :new
        end
    end
    
    def update
        attributes = @current_user.moderator? ? params[:discussion] : Discussion.safe_attributes(params[:discussion])
        @discussion.update_attributes(attributes.merge(:new_closer => @current_user))
        if @discussion.valid?
            flash[:notice] = "Your changes were saved."
            redirect_to discussion_path(@discussion) and return
        else
            flash.now[:notice] = "Could not save your discussion, did you fill in all required fields?"
            render :action => :edit
        end
    end

	def favorites
		@section = :favorites
		@discussions = @current_user.favorite_discussions(:page => params[:page], :trusted => @current_user.trusted?)
		find_discussion_views
	end
	
	def following
		@section = :following
		@discussions = @current_user.following_discussions(:page => params[:page], :trusted => @current_user.trusted?)
		find_discussion_views
	end

	def follow
		DiscussionRelationship.define(@current_user, @discussion, :following => true)
		redirect_to discussion_url(@discussion, :page => params[:page])
	end
    
	def unfollow
		DiscussionRelationship.define(@current_user, @discussion, :following => false)
		#redirect_to discussion_url(@discussion, :page => params[:page])
		redirect_to discussions_url
	end

	def favorite
		DiscussionRelationship.define(@current_user, @discussion, :favorite => true)
		redirect_to discussion_url(@discussion, :page => params[:page])
	end
    
	def unfavorite
		DiscussionRelationship.define(@current_user, @discussion, :favorite => false)
		redirect_to discussion_url(@discussion, :page => params[:page])
	end
end
