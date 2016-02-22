=== 0.8.5 computed field support

```coffee
class MyModel extends Sirius.BaseModel
  @attrs: ["first_name", "last_name", "age"]
  @comp("full_name", "first_name", "last_name")
  @comp("age_and_full_name", "age", "full_name", (age, fn) -> "age: #{age}, #{fn}")  
```

=== 0.8.4 

add `zoom` for views

```html
<div id="view">
  <span class="inner"></span>
</div>
```

```coffee
view = new Sirius.View("#view")
view.zoom(".inner").swap("new content")
```

result:

```html
<div id="view">
  <span class="inner">new content</span>
</div>
```

=== 0.8.3

Binding one selector with several model attributes:

```javascript
model.bind(view, { 
  "#example": [{
    from: "description"
  }, {
    from: "title",
    to: "class"
  }]
});
```

Set model attributes from view in binding.

Enable logging for developer code.

Now if `log_filters` is `[]`, then all application logs disabled.

Safe memory handling on event defined in controllers, like:

```coffee
Controller = 
  method: () ->
    m = new Mode()
    v = new Sirius.View("#element")
    v.on("selector", "click", (e) -> 
      # ...
```



=== 0.8.2

add cache for prevent memory leak, in code like:

```
Controller =
  action: () ->
    model = new MyModel()
    view = new Sirius.View("element")
    model.bind(v, {
      ...
    })
    
    view.on "input[type='button']", "click", (e) ->
      #code
    
```

Now Sirius use cache, and with every action will be created only one handler.


=== 0.7.2 

Logger improvement

New options for `run`: `log_filters`

In `log_filters` need define filters for logs from different places of Sirius. Example:

```coffee
# BaseModel   = 0
# Binding     = 1
# Collection  = 2
# View        = 4
# Routing     = 5
# Application = 7
# Redirect    = 8
# Validation  = 9
 
Sirius.Application.run
  log_filters: [0, 1, 9] # in console logs only from BaseModel, BindHelper, and Validators
  # or 
  log_filters: ["BaseModel", "Application", "View"]
```

`mix_logger_into_controller` - add logger into you controller:

```coffee

Sirius.Application.run
  mix_logger_into_controller : true # by defualt
  routes: 
    application:run : () ->
      logger.info("run!!!") # => INFO: run!!!
      logger.debug("seems all ok") # => DEBUG: seems all ok
      logger.warn("oops") # => WARN: oops
      logger.error("ERROR") # => ERROR: ERROR
      # or 
      logger.info("run!!!", "MyRunController") # => INFO: [MyRunController] run!!!
      # etc...

```

`data-bind-to`, `data-bind-from` removed from code. Use object setting like

```js
model.bind(view, {
  '.model-id'         : {from: "id", to: "data-name"}
  '.model-title'      : {from: "title", to: "data-name"}
  '.model-description': {from: "description", to: "data-name"}
})

```

`skip` options for `Sirius.BaseModel`:

```coffee
class ModelA extends Sirius.BaseModel
  @attrs: ["id"]

class ModelB extends Sirius.BaseModel
  @attrs: ["id"]
  @skip : true

obj = {"id": 1, "foo" : "bar" }
new ModelA(obj) # => error
new ModelB(obj) # => ok

```

`index` for collection. For unique fields you might use indexes with collections.
This improve search by feild.

```coffee
# MyModel = id, title, description

models = new Sirius.Collection(MyModel, {index: ["id"]})

```

#### add VanillaJs Adapter.

#### improvement for work with logical element in binding


=== 0.7.1 

tests for prototypejs










