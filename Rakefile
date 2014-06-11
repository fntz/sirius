require 'rake'
require 'net/http'
require 'uri'
require 'openssl'

task :install do
  vendor = "vendor"
  deps = [
           "https://ajax.googleapis.com/ajax/libs/prototype/1.7.2.0/prototype.js",
           "https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.js",
           "https://raw.githubusercontent.com/visionmedia/mocha/master/lib/mocha.js",
           "https://raw.githubusercontent.com/visionmedia/mocha/master/mocha.css",
           "https://raw.githubusercontent.com/chaijs/chai/master/chai.js"
         ]
  begin
    if !File.directory?(vendor)
      FileUtils.mkdir(vendor)
      puts "Create a #{vendor} directory"
    end

    deps.each do |lib|
      name = lib.split("/").last
      if !File.exist?("#{vendor}/#{name}")
        puts "download: #{name}"

        uri = URI.parse("#{lib}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = http.get(uri.request_uri)
        File.open("#{vendor}/#{name}", "w") do |f|
          f.write(response)
        end
      end
    end

  rescue Exception => e
    puts e
  end
end

task :test do
  %x(coffee -b -c test/fixture.coffee)
  %x(coffee -b -c -o lib/ src/)
end

task :build do
  exec("coffee -c -o lib/ src/")
end

task :doc do
  #todo
end









