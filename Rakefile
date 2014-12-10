require 'rake'
require 'net/http'
require 'uri'
require 'openssl'
require "open-uri"


def download_and_save(arr, path)
  begin
    if !File.directory?(path)
      FileUtils.mkdir_p(path)
      puts "Create a #{path} directory"
    end

    arr.each do |lib|
      name = lib.split("/").last
      if !File.exist?("#{path}/#{name}")
        puts "download: #{name}"

        response = URI.parse("#{lib}").read
        File.open("#{path}/#{name}", "w") do |f|
          f.write(response)
        end
      end
    end

  rescue Exception => e
    puts "Exception: #{e}"
  end
end

desc "Install dependencies"

task :jasmine_install do
  deps = %w{
    https://raw.githubusercontent.com/jasmine/jasmine/master/lib/jasmine-core/boot/boot.js
    https://raw.githubusercontent.com/jasmine/jasmine/master/lib/jasmine-core/jasmine.js
    https://raw.githubusercontent.com/jasmine/jasmine/master/lib/jasmine-core/jasmine.css
    https://raw.githubusercontent.com/jasmine/jasmine/master/lib/jasmine-core/jasmine-html.js
    https://raw.githubusercontent.com/jasmine/jasmine/master/images/jasmine_favicon.png
    https://raw.githubusercontent.com/jasmine/jasmine/master/MIT.LICENSE
  }


  path = "test/jasmine/lib"

  download_and_save(deps, path)
end

task :vendor_install do
  vendor = "vendor"
  deps = [
           "https://ajax.googleapis.com/ajax/libs/prototype/1.7.2.0/prototype.js",
           "http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js",
           "https://raw.githubusercontent.com/dwachss/bililiteRange/master/bililiteRange.js",
           "https://raw.githubusercontent.com/dwachss/bililiteRange/master/jquery.sendkeys.js",
           "https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar",
           "https://raw.githubusercontent.com/kangax/protolicious/master/event.simulate.js"
         ]
  download_and_save(deps, vendor)
end

desc "Install vendor dependencies and jasmine 2.0"
task :install => [:vendor_install, :jasmine_install] do

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

def coffee(path, arr)
  arr.map{|x| "#{path}/#{x}.coffee"}.join(" ")
end


desc "Compile to javascript"
task :build do
  path = "lib"
  if !File.directory?(path)
    FileUtils.mkdir_p(path)
    puts "Create a #{path} directory"
  end

  src = "src"

  prototype_files = coffee(src, %w(adapter prototype_js_adapter))
  jquery_files = coffee(src, %w(adapter jquery_adapter))
  lib_files = coffee(src, %w(
    version ext logger promise sirius
    utils validators observer
    bind_helper view base_model collection
  ))

  system("cat #{lib_files} | coffee -c -b --stdio > #{path}/sirius.js")
  system("cat #{prototype_files} | coffee -c -b --stdio > #{path}/prototypejs_adapter.js")
  system("cat #{jquery_files} | coffee -c -b --stdio > #{path}/jquery_adapter.js")
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

