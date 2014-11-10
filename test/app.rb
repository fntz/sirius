require 'sinatra'

set :public_folder, File.dirname(__FILE__)

get '/' do
   File.read("#{File.dirname(__FILE__)}/SpecRunner.html")
end

get '/:dir/:file' do
  file = params[:file]
  dir  = params[:dir]
  if file.end_with?("css")
    content_type "text/css"
  elsif file.end_with?("js")
    content_type "text/javascript"
  end

  File.read("#{Dir.pwd}/#{dir}/#{file}")
end
