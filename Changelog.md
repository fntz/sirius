=== 0.7.1 

tests for prototypejs

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











