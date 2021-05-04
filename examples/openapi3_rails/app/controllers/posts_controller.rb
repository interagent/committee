class PostsController < ApplicationController
    def create
        render status: 201, json: {title: "abc", page: params[:page], year: params[:year]}
    end
    def create_with_id
        render status: 201, json: {title: "abc", page: params[:page], year: params[:year]}
    end
end
