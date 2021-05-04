Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  post :posts, to: 'posts#create'
  post '/posts/:id', to: 'posts#create_with_id'
end
