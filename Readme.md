
[Sirius.js](http://fntzr.github.com/sirius) a coffeescript MVC framework.
[post: Todo App with Sirius.js](http://fntz.github.io/coffeescript/2014/12/18/writing-todo-app-with-sirius.html)

### browser support: IE9+, FF, Opera, Chrome


### Features

+ Template free — you may use any template engine or use any at all
+ MVC style
+ MVVM binding (view to view, model to view, view to model, object property to view)
+ Build-in Collections 
+ Build-in Validators
+ Simple for customization
+ Adapters for jQuery, Prototype.js and for Vanillajs
+ Support html5 routing, and converters to html5 routing
+ Log all actions in application
+ Share actions between controllers
+ And many others

# Install

`npm install sirius` 

or download manually [sirius.min.js](https://raw.githubusercontent.com/fntzr/sirius/master/sirius.min.js) and [jquery_adapter.min.js](https://raw.githubusercontent.com/fntzr/sirius/master/jquery_adapter.min.js) or [prototype_js_adapter.min.js](https://raw.githubusercontent.com/fntzr/sirius/master/prototypejs_adapter.min.js) from repo.

#### TODO

1. `grep -r -i -e 'fixme' -e 'todo' src`
2. more tests

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

#### 1.1 Advanced with controllers

Sometimes you need share some actions between all controllers - logger, ajax requests, or some like this, that simple:

```coffee

CommonMethods =

  ajax: (args...) ->
  logger: (args...) ->
  another_action: (args...) ->

# then
  Sirius.Application.run
    route: # you routes
    adapter: # some adapter
    controller_wrapper : CommonActions

# and now in you controller:

Controller =
  action: (url) =
    # possible use
    # any method from CommonActions, like
    logger("start ajax request")
    response = ajax(url)
    logger("stop ajax request, response #{response} given")

```

##### note: by default Sirius `controller_wrapper` contain only `redirect` action, and with `mix_logger_into_controller` options you might enable logger in controller actions


### 2. Define routes

```coffee
  routes =
    "application:run"   : controller: MyController, action: "action"
    "/plain"            : controller: MyController, action: "plain"
    "#/:title"          : controller: MyController, action: "run"
    "click #my-element" : controller: MyController, action: "event_action", guard: "guard_event", data: "id"  

```

### 3. Define models

```coffee
  
  class Person extends Sirius.BaseModel
     @attrs: ["id", "name", "age"]
     @comp("id_and_name", "id", "name") # <- computed field
     @guid_for: "id"
     @validate:
       id: c only_integers: true

```

For work with models from javascript code, define models like:

```js

var MyModel = Sirius.BaseModel.define_model({
  attrs: ["id", "name", "age"],
  validate: {id: { numericality: { only_integers: true } } }
  instance_method: function(){ }
})

var my_model = new MyModel()
my_model.id() // => some guid
my_model.instance_method() // => call

```

### 4. Run Application

```coffee
  Sirius.Application.run({route: routes, adapter: new YourAdapter()})
```

### 5. Use Validators

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

#### 5.1 Define custom Validator

```coffee
  class MyValidator extends Sirius.Validator
    validate: (value, attrs) ->
      if value.length == 3
        @msg = "Error, value should have length 3"
        false
      else
        true

# register validator
Sirius.BaseModel.register_validator("my_validator", MyValidator)

# and use
  class MyModel extends Sirius.BaseModel
    @attrs: ["title"]
    @validate:
      title:
        my_validator: some_attribute: true

```

### 6. Views

In Sirius, views is an any element on page. You might bind view and other view, or model, or javascript object property.

```coffee
  view = new Sirius.View("#id", (x) -> "#{x}!!!")
  view.render("new content").swap()
  # then in html <element id='id'>new content!!!</element>
```

`swap` - this strategy, how work with content. Support: `swap`, `append`, `prepend` stretegies.

Define own strategy:

```coffee
 Sirius.View.register_strategy('html',
    transform: (oldvalue, newvalue) -> "<b>#{newvalue}<b>"
    render: (adapter, element, result, attribute) ->
      if attribute == 'text'
        $(element).html(result)
      else
        throw new Error("Html strategy work only for text, not for #{attribute}")
 )

# use it

view = new Sirius.View("#element")
view.render("some text").html()

# then in html

<span id='element'><b>some text</b></span>
```

Also you might swap content for any attribute:

```coffee
view.render("active").swap('class')
```

### 7. Use collections

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

### 8. Binding

Support binding: view to model, view to view, view to model, view to javascript object property
and model to view. And it support all strategies (how to change content or attribute) or transform (how to transform value) methods.


```coffee
# view to view
 # html
 <input type='text' id='v1' />
 <span id='r1'></span>

 # coffee
 view1 = new Sirius.View('#v1')
 view2 = new Sirius.View('#r1')
 v1.bind(r1)

 # when we enter some text into input
 # then
 $("#r1").data('name') # => equal to our input
```

```coffee
# view to model
  # html
  <form id="form">
    <input type='text'>
    <textarea></textarea>
  </form>

  # coffee
  view = new Sirius.View("#form")
  my_model = new MyModel()
  view.bind(my_model, {
    'input': {to: "title"}
    'textarea': {to: "description"} 
  })

  # When we enter input, then
  my_model.title() # => user input
  my_model.description() # => user input

```

```
# view to object property
//html
 <span></span>

 my_collection = new Sirius.Collection(MyModel)
 view = new Sirius.View("span")
 view.bind(my_collection.length)

 my_collection.push(new MyModel())
 # then in html
 <span>1</span>
```

```
# model to view
<form id='my-form'>
  <input name="cgroup" type="checkbox" value="val1" />
  <input name="cgroup" type="checkbox" value="val2" />
  <input name="cgroup" type="checkbox" value="val3" />
</form>

# you model is only Model with one attribute `model_value`
model = new Model({choice: {}})
view = new Sirius.View("#my-form")
model.bind(view, {
  "input[type='checkbox']" : { from: "choice", to: "checked" } # for logical element use checked 
})

# use it
model.model_value("val3")
# in element
$("#my-form input:checked").val() # => val3

```
Strategies and transform for binding

```coffee

# model
source = new Source() # fields: `normalized`, `count`, `id`...  
# view
source_view = new Sirius.View("#source-id")

source.bind(source_view,
    "a.source-url":            # bind for `href` and `text` (content) 
      [{           
        from: "normalized"
        to: "href"
        transform: (x) ->  # wrap field
          "/show/#{x}"}, 
      {
        from: "name"
        to: "text"
      }]


    "span.source-count":
      from: "count"
      transform: (x) ->  # transform to normal string from int
        if isNaN(parseInt(x, 10)) || x <= 0  
          "0"
        else
          "#{x}"
      strategy: "hide" # custom strategy if count eq 0, add hide class
  )
  
```



# More info

+ [Project page](http://fntzr.github.io/sirius)
+ [TodoMVC Application](http://fntzr.github.io/sirius/todomvc/index.html) and [source](https://github.com/fntzr/sirius/blob/master/todomvc/js/app.coffee)
+ [Docs](http://fntzr.github.io/sirius/doc/index.html)



# Tasks

Use `rake` for run task. Before work run `rake install` for installing dependencies.

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
