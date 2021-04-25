class PostsController < ApplicationController
    def create
        render status: 201, json: {title: "abc", page: params[:page], year: params[:year]}
    end
end
