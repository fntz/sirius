# Are you sirius?


[Sirius.js](http://fntzr.github.com/sirius) a coffeescript MVC framework. It's give a simple integration with current javascript frameworks.

### current version: 0.6.1
### browser support: IE10+, FF, Opera, Chrome
#### Note: ie9 support coming soon

### Features

+ Template free — you may use any template engine or use any at all
+ MVC style
+ MVVM binding (view to view, model to view, view to model, object property to view)
+ Build-in Collections, Validators
+ Adapters for jQuery and Prototype.js
+ Support html5 routing, and converters to html5 routing

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
     @guid_for: "id"
     @form_name: "my-person-form"

```

### 4. Run Application

```coffee
  Sirius.Application({route: routes})
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
and model to view. And it support all strategies or transform methods.


```
# view to view
 # html
 <input type='text' id='v1' />
 <span id='r1' data-bind-to='data-name'></span>

 # coffee
 view1 = new Sirius.View('#v1')
 view2 = new Sirius.View('#r1')
 v1.bind(r1)

 # when we enter some text into input
 # then
 $("#r1").data('name') # => equal to our input
```

```
# view to model
  # html
  <form id="form">
    <input type='text' data-bind-to='title'>
    <textarea data-bind-to='description'></textarea>
  </form>

  # coffee
  view = new Sirius.View("#form")
  my_model = new MyModel()
  view.bind(my_model)

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
  <input type="checkbox" value="val1" data-bind-view-from='model_value' />
  <input type="checkbox" value="val2" data-bind-view-from='model_value' />
  <input type="checkbox" value="val3" data-bind-view-from='model_value' />
</form>

# you model is only Model with one attribute `model_value`
model = new Model()
view = new Sirius.View("#my-form")
model.bind(view)

# use it
model.model_value("val3")
# in element
$("#my-form input:checked").val() # => val3

```
Strategies and transform for binding

```html
  <span data-bind-view-from='title' data-bind-view-transform='wrap' data-bind-view-strategy='append'></span>
```

##### double-sided binding

```coffee
view.bind2(model)
# or
model.bind2(view)
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

<p align="center">
  <img src="http://makeameme.org/media/created/YEAH-I-AM-n5trg3.jpg?raw=true" alt="I am Sirius"/>
</p>
