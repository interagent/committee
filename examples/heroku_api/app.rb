require 'sinatra'
require 'committee'

set :port, 9292

use Committee::Middleware::RequestValidation, schema_path: './openapi.yaml', coerce_date_times: true

post '/account/app-transfers' do
end

get '/search' do
end

post '/apps' do
end
