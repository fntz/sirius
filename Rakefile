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

  # unzip closure
  %x(unzip -u -d vendor vendor/compiler-latest.zip)

end

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
           "https://cdnjs.cloudflare.com/ajax/libs/prototype/1.7.3/prototype.js",
           "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js",
           "https://raw.githubusercontent.com/dwachss/bililiteRange/master/bililiteRange.js",
           "https://raw.githubusercontent.com/dwachss/bililiteRange/master/jquery.sendkeys.js",
           "http://dl.google.com/closure-compiler/compiler-latest.zip",
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

  prototype_files = coffee(src, %w(comment_header adapter prototype_js_adapter))
  jquery_files = coffee(src, %w(comment_header adapter jquery_adapter))
  vanilla_files = coffee(src, %w(comment_header adapter vanilla_js_adapter))

  lib_files = coffee(src, %w(
    comment_header version adapter vanilla_js_adapter
    logger internal promise utils
    sirius validators observer
    view base_model transformer collection
  ))

  system("cat #{lib_files} | coffee -c -b --stdio > #{path}/sirius.js")
  system("cat #{prototype_files} | coffee -c -b --stdio > #{path}/prototypejs_adapter.js")
  system("cat #{jquery_files} | coffee -c -b --stdio > #{path}/jquery_adapter.js")
  system("cat #{vanilla_files} | coffee -c -b --stdio > #{path}/vanillajs_adapter.js")
end

desc "Create doc"
task :doc do
  %x(codo src)
end

desc "Minify sources"
task :minify => [:build] do
  cc = Dir["vendor/closure-*.jar"]
  if cc.empty?
    p "Install closure-compiler first"
  else
    compiler = cc.first
    %x[java -jar #{compiler} --js_output_file=sirius.min.js lib/sirius.js]
    %x[java -jar #{compiler} --js_output_file=jquery_adapter.min.js lib/jquery_adapter.js]
    %x[java -jar #{compiler} --js_output_file=prototypejs_adapter.min.js lib/prototypejs_adapter.js]
    %x[java -jar #{compiler} --js_output_file=vanillajs_adapter.min.js lib/vanillajs_adapter.js]
  end
end


namespace :todo do
  desc "TODOApp compile"
  task :compile => [:build] do
    app = 'todomvc'
    app_files = coffee(app, [
      "js/utils/template",
      "js/utils/utils",
      "js/models/task",
      "js/utils/utils",
      "js/utils/constants",
      "js/utils/renderer",
      "js/controllers/main_controller",
      "js/controllers/todo_controller",
      "js/controllers/bottom_controller",
      "js/controllers/link_controller",
      "js/app"
    ])

    system("cat #{app_files} | coffee -c -b --stdio > #{app}/js/app.js")
  end

  desc "Run TODO app"
  task :run => ['todo:compile'] do
    system("ruby todomvc/app.rb")
  end
end

task :default => :build

