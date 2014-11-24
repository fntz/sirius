require 'rake'
require 'net/http'
require 'uri'
require 'openssl'
require "open-uri"

desc "Install dependencies"
task :install do
  vendor = "vendor"
  deps = [
           "https://ajax.googleapis.com/ajax/libs/prototype/1.7.2.0/prototype.js",
           "https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.js",
           "https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar"
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

        response = URI.parse("#{lib}").read
        File.open("#{vendor}/#{name}", "w") do |f|
          f.write(response)
        end
      end
    end

  rescue Exception => e
    puts e
  end
end

desc "Compile test sources"
task :test_compile => [:build] do
  puts "===== recompile..."
  %x(coffee -b -c test/fixtures.coffee)
  Dir["test/specs/source/*"].each do |file|
    name = File.basename(file, ".coffee")
    %x(coffee -o test/specs/compile -b -c #{file})
  end
end

desc "Run test app"
task :test => [:build, :test_compile] do
  system("ruby test/app.rb")
end

desc "Compile to javascript"
task :build do
  files = Dir["src/*.coffee"]
  without_adapter = files.find_all{|f| !f.include?("adapter") }

  output0 = without_adapter.join(" ")
  output_jquery = "src/adapter.coffee src/jquery_adapter.coffee"
  output_prototype = "src/adapter.coffee src/prototype_js_adapter.coffee"
  %x(coffee -b -j sirius.js -o lib/ -c #{output0})
  %x(coffee -b -j jquery_adapter.js -o lib/ -c #{output_jquery})
  %x(coffee -b -j prototypejs_adapter.js -o lib/ -c #{output_prototype})
end

desc "Create doc"
task :doc do
  %x(codo src)
end

desc "Minify sources"
task :minify => [:build] do
  %x(java -jar vendor/yuicompressor-2.4.8.jar --type=js --nomunge lib/sirius.js -o sirius.min.js)
  %x(java -jar vendor/yuicompressor-2.4.8.jar --type=js --nomunge lib/jquery_adapter.js -o jquery_adapter.min.js)
  %x(java -jar vendor/yuicompressor-2.4.8.jar --type=js --nomunge lib/prototypejs_adapter.js -o prototypejs_adapter.min.js)
end


namespace :todo do
  desc "TODOApp compile"
  task :compile do
    %x(coffee -c -b todomvc/js/app.coffee)
  end

  desc "Run TODO app"
  task :run => ['todo:compile'] do
    system("ruby todomvc/app.rb")
  end
end

task :default => :build

