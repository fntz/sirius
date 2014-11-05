# Are you sirius?


[Sirius.js](http://fntzr.github.com/sirius) a coffeescript MVC framework. It's give a simple integration with current javascript frameworks.

### Features


+ Template free — you may use any template engine or use any at all
+ Controller free — you may use object as Controllers for you application or use only functions as controllers
+ Model free — you may use a built in models, or use alternative model implementation from `Backbone.js` or `Ember.Data` or use javascript objects as you models.
+ Javascript framework free — you may create a Adapter for own framework or use for `jQuery` or `prototypejs` adapters.
+ Routing - routing from hash changes, from events, from custom events
+ Possible use plain routing, if browser not support plain routing, then `Sirius` automatically switch to hash-based routing
+ Include MVVM Support
+ Easy for understanding

You only need define Route for you application.

# Install

`npm install sirius` 

or download manually [sirius.min.js](https://raw.githubusercontent.com/fntzr/sirius/master/sirius.min.js) and [jquery_adapter.min.js](https://raw.githubusercontent.com/fntzr/sirius/master/jquery_adapter.min.js) or [prototype_js_adapter.min.js](https://raw.githubusercontent.com/fntzr/sirius/master/prototypejs_adapter.min.js) from repo.

# Usage

### 1. Define controllers

```coffee
MyController = 
  action: (param) ->
    # ...
  
  run: () ->
    # ...
  after_run: () ->
    # run after `run` method
    
  guard_event: (event) ->
    if condition 
      true 
    else 
      false
      
  event_action: (event, id) ->
    # ...

```

### 2. Define routes

```coffee
  routes = {
    "application:run"   : controller: MyController, action: "action"
    "/plain"            : controller: MyController, action: "plain"
    "#/:title"          : controller: MyController, action: "run"
    "click #my-element" : controller: MyController, action: "event_action", guard: "guard_event", data: "id"  
  } 

```

### 3. Define models

```coffee
  
  class Person extends Sirius.BaseModel
     @attrs: ["id", "name", "age"]
     @guid_for: "id"
     @form_name: "my-person-form"
          
   
```

### 4. Run Application

```coffee
  Sirius.Application({routes: routes}) 
```

#### 5. Use Validators

```coffee
  class Person extends Sirius.BaseModel
    @attrs: ["id", "name", "age"]
    @guid_for: "id"
    @form_name: "my-person-form"
    @validate :
      name:
        presence: true
        format: with: /^[A-Z].+/
        length: min: 3, max: 7
        exclusion: ["title"]
```

#### 6. Use collections

```coffee
persons = new Sirius.Collection(Person, [], {
  every : 5000,
  remote: () -> #ajax call
  on_add: (model) ->
    # sync with server
    # add into html
  on_remove: (model) ->
    # sync with server
    # remove from html
})
joe = new Person({"name": "Joe", "age" : 25})

persons.add(joe)

person.find("name", "Joe").to_json() # => {"id" : "g-u-i-d", "name" : "Joe", "age" : 25}
```


# More info

+ [Project page](http://fntzr.github.io/sirius)
+ [TodoMVC Application](http://fntzr.github.io/sirius/todomvc/index.html) and [source](https://github.com/fntzr/sirius/blob/master/todomvc/js/app.coffee)
+ [Docs](http://fntzr.github.io/sirius/doc/index.html)



# Tasks

Use `cake` or `rake` for run task. Before work run `rake or cake install` for installing dependencies.

`rake install` - install all dependencies

`rake doc` - generate project documentation

`rake build` - compile coffeescript into javascript file

`rake test` - complile fixtures for tests, and run server

`rake minify` - use [yuicompressor](https://github.com/yui/yuicompressor) for minify files

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request





### LICENSE : MIT

<p align="center">
  <img src="http://makeameme.org/media/created/YEAH-I-AM-n5trg3.jpg?raw=true" alt="I am Sirius"/>
</p>
