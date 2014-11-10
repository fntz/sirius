fs    = require 'fs'
http  = require 'http'
https = require 'https'
exec  = require('child_process').exec

log = (msg) -> console.log(msg)

exe = (msg) ->
  exec(msg, (error, out, err) ->
    if error isnt null
      log("given error: #{err}")
  )

doc = () -> exe("codo src")

minify = () ->
  build()
  base = "java -jar vendor/yuicompressor-2.4.8.jar --type=js --nomunge"
  arr = ["lib/sirius.js -o sirius.min.js", "lib/jquery_adapter.js -o jquery_adapter.min.js", "lib/prototypejs_adapter.js -o prototypejs_adapter.min.js"]
  for i in arr then exe("#{base} #{i}")

test = () ->
  build()
  exe("source -b -c test/fixtures.source")

build = () ->
  fs.readdir("src/", (err, files) ->
    if !err
      without_adapter = for f in files when f.indexOf("adapter") == -1 then "src/#{f}"
      output0 = without_adapter.join(" ")
      output_jquery = "src/adapter.source src/jquery_adapter.source"
      output_prototype = "src/adapter.source src/prototype_js_adapter.source"
      exe("source -b -j sirius.js -o lib/ -c #{output0}")
      exe("source -b -j jquery_adapter.js -o lib/ -c #{output_jquery}")
      exe("source -b -j prototypejs_adapter.js -o lib/ -c #{output_prototype}")
    else
      log("build error #{err}")
  )

install = () ->
  vendor = "vendor"
  deps = [
    "https://ajax.googleapis.com/ajax/libs/prototype/1.7.2.0/prototype.js",
    "https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.js",
    "https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar"
  ]
  try
    exe("mkdir -p #{vendor}")

    download = (n) ->
      i = deps[n]
      return if !i

      z = i.split("/")
      file_name = z[z.length-1]
      file = fs.createWriteStream("#{vendor}/#{file_name}")

      log("download #{file_name}")

      if i.indexOf("https") == -1
        http.get(i, (response) ->
          response.pipe(file)
          download(n+1)
        )
      else
        https.get(i, (response) ->
          response.pipe(file)
          download(n+1)
        )

    download(0)

  catch e
    log ("Exception on install dependencies #{e}")


task 'install', "Install dependencies", install
task 'build', "Complile to javascript", build
task 'test', "Compile fixtures", test
task 'doc', "Create doc", doc
task 'minify', "Minify sources", minify