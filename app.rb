require 'sinatra/base'

module DistelliDemo; end

class DistelliDemo::App < Sinatra::Base
  get '/' do
    'Hello, world!'
  end
end
