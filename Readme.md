
`Sirius` is a modern coffeescript MVC/MVVM framework for client side.

[wiki](https://github.com/fntz/sirius/wiki)

[todoapp sources](https://github.com/fntz/sirius/tree/master/todomvc)

### browser support: IE9+, FF, Opera, Chrome

### Features

+ Template free — you may use any template engine or use any at all
+ MVC style
+ MVVM binding (view to view, model to view, view to model, object property to view)
+ Build-in Collections 
+ Build-in Validators
+ Simple for customization
+ Adapters for jQuery, Prototype.js and for Vanillajs
+ Support html5 routing
+ Time events in routing
+ Log all actions in application [read about it](https://github.com/fntz/sirius/wiki/Logger)
+ Share actions between controllers
+ And many others

# Install

`npm install sirius` 

or download manually [sirius.min.js](https://raw.githubusercontent.com/fntz/sirius/master/sirius.min.js) and [jquery_adapter.min.js](https://raw.githubusercontent.com/fntz/sirius/master/jquery_adapter.min.js) or [prototype_js_adapter.min.js](https://raw.githubusercontent.com/fntz/sirius/master/prototypejs_adapter.min.js) from repo.

or only core part: [sirius-core.min.js](https://raw.githubusercontent.com/fnt/sirius/master/sirius-core.min.js)

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
    "every 10s"         : controller: MyController, action: "refresh"
    "click #my-element" : controller: MyController, action: "event_action", guard: "guard_event", data: "id"  

```

[more about routing and controllers](https://github.com/fntz/sirius/wiki/Controllers-and-Routing)

### 3. Define models

```coffee
  
  class Person extends Sirius.BaseModel
     @attrs: ["id", "name", "age"]
     @comp("id_and_name", "id", "name") # <- computed field
     @guid_for: "id"
     @validate:
       id: only_integers: true

```

[more about models](https://github.com/fntz/sirius/wiki/Models)

### 4. Run Application

```coffee
  Sirius.Application.run({route: routes, adapter: new YourAdapter()})
```

[more about application and settings](https://github.com/fntz/sirius/wiki/Application-&-Settings)

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

[more about validators](https://github.com/fntz/sirius/wiki/Validators)

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

[more about views](https://github.com/fntz/sirius/wiki/Views)

### 7. Use collections

```coffee
persons = new Sirius.Collection(Person, {index: ['name']})
joe = new Person({"name": "Joe", "age" : 25})

persons.add(joe)

person.find("name", "Joe").to_json() # => {"id" : "g-u-i-d", "name" : "Joe", "age" : 25}
```

[more about collections](https://github.com/fntz/sirius/wiki/Collections)

### 8. Binding

Support binding: view to model, view to view, model to view, or model|view to function. 
And it support all strategies (how to change content or attribute) or transform (how to transform value) methods.


```coffee
# view to view
# html

# view1 
<div id="element">
  <p></p>
</div>

# view2
<div id="my-input">
  <input type="text" />
</div>

view1 = new Sirius.View("#element")
view2 = new Sirius.View("#my-input")

transformer = Sirius.Transformer.draw({
  to: [{
    from: 'input'
    selector: 'p'
    via: (new_value, selector, view, attribute) ->
      view.zoom(selector).render(new_value).swap(attribute) 
  }]
})

view2.bind(vew1, transformer)
```

```coffee
# view to model
# html
<div id="my-input">
  <input type="text" />
</div>

model = new MyModel() 
view = new Sirius.View("#my-input")
transformer = Sirius.Transformer.draw({
  "input": {
    to: 'title'
    from: 'text'
    via: (new_value, view, selector, from, event_target) ->
      new_value
  }
})

# and then fill input, and check

model.title() # => your input

```

```coffee
# model to view
<<div id="element">
   <p></p>
 </div>
 
 model = new MyModel() # [id, title]
 view = new Sirius.View("#element")
 
 transformer = Sirius.Transformer.draw({
   "title": {
     to: 'p'
     attr: 'text'
     via: (new_value, selector, view, attribute) -> 
       view.zoom(selector).render(new_value).swap(attribute)
   }
 })
 
 model.bind(view, transformer) 
 
 # and then in application:
 
 model.title("new title") 
 
 # and new html
 
 <div id="element">
   <p>new title</p>
 </div>

```

[more about binding](https://github.com/fntz/sirius/wiki/Binding)



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
