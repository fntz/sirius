###
  Create Binding between Model and View and vice versa
  @see https://github.com/fntz/sirius/issues/31

  This class have own Logger Name [Transformer]

  i.e. Pipe

  note only one `pipe` between one model class and view class

  @example

    #Base Idea

    <input id='my-name' type='text' />

    class MyModel extends Sirius.Model
      @attrs: ['name']

    view = new Sirius.View("#my-name")

    model = new MyModel()


    pipe_view_to_model = Sirius.Transformer.draw
      "#my-name":
        to: 'name'
        from: 'text' # class, id, *, default: text
        via: (value) ->
          return "#{value}!!!"

    view.bind(model, pipe_view_to_model)


    pipe_model_to_view = Sirius.Transformer.draw
      "name":
        to: "#my-name"
        via: (value, selector, view) ->
          @view.zoom(selector).set_value(value)
        # or maybe

    model.bind(view, pipe_model_to_view)


  Small notes:
  + Only one pipe
  + Need method for reverse pipe (from view to model -> from model to view)
  + Draw default for simple cases (text to text)


  Questions:
  + How to transformer should works between js objects?

###

Sirius.Internal = {}

class Sirius.Internal.AbstractTransformer

  constructor: (@_path, @_from, @_to) ->
    @logger = Sirius.Application.get_logger()
    @_ln = @logger.transformer # logger name
    @_register()

  _register: () ->


class Sirius.Internal.ToFunctionTransformer extends Sirius.Internal.AbstractTransformer
  _register: () ->
    @_from._register_state_listener(@)
    clb = @_fire_generator()
    top = @_from.get_element()
    for k, v of @_path
      new Sirius.Observer("#{top} #{k}", k, clb)

  _fire_generator: () ->
    view = @_from
    logger = @logger
    f = @_to

    callback = (result) ->
      f(result, view, logger)

    callback

# @private
# @nodoc
class Sirius.Internal.ToViewTransformer extends Sirius.Internal.AbstractTransformer
  _register: () ->
    clb = @_fire_generator()
    @_from._register_state_listener(clb)

  @_default_via_method: () ->
    (value, selector, view) ->
      view.zoom(selector).render(value).swap()

  _fire_generator: () ->
    view = @_to
    path = @_path
    model = @_from
    logger = @logger
    ln = @_ln

    callback = (attribute, value) ->
      obj = path[attribute]

      if obj
        logger.debug("Apply new value for '#{attribute}' for '#{view.get_element()}', value: #{value} from #{model.normal_name()}", ln)
        to = obj['to']
        via = obj['via'] || Sirius.Internal.ToViewTransformer._default_via_method()

        via(value, to, view)

    callback

# @private
# @nodoc
class Sirius.Internal.ToModelTransformer extends Sirius.Internal.AbstractTransformer
  _register: () ->
    @_from._register_state_listener(@)
    clb = @_fire_generator()
    top = @_from.get_element()
    for k, v of @_path
      new Sirius.Observer("#{top} #{k}", k, clb)

  _default_via_method: () ->
    (value) -> value

  _fire_generator: () ->
    view = @_from
    path = @_path
    model = @_to
    logger = @logger
    ln = @_ln

    callback = (result) ->

      value = path[result.original]
      if value
        to = value['to']
        from = value['from'] || 'text'
        via = value['via'] || ((value) -> value)

        logger.debug("Apply new value from #{result.from} (#{result.original}) to #{model.normal_name()}.#{to}", ln)

        model.set(to, via(result.text))

    callback


class Sirius.Transformer
  # from
  @_Model :  0
  @_View  :  1

  # to
  # Model, View, Function
  @_Function: 2

  _from: null

  _to: null

  # hash object
  _path: null

  constructor: (from, to) ->
    @logger = Sirius.Application.get_logger()
    @ln = @logger.transformer

    if from instanceof Sirius.BaseModel
      @_from = from
    else if from instanceof Sirius.View
      @_from = from
    else
      throw new Error("Bad argument for Transformer, Model or View required, given #{from}")

    if to instanceof Sirius.BaseModel
      if !(@_from instanceof Sirius.BaseModel)
        @_to = to
      else
        throw new Error("Impossible bind model and model")
    else if to instanceof Sirius.View
      @_to = to
    else if Sirius.Utils.is_function(to)
      @_to = to
    else
      throw new Error("Bind works only with BaseModel, BaseView or Function, given: #{to}")


  # called implicitly with `via` method in binding
  run: (object) ->

    if @_from && @_to
      if @_from instanceof Sirius.BaseModel
        for k, v of object
          if @_from.get_attributes().indexOf(k) == -1
            name = @_from.normal_name()
            attrs = @_from.get_attributes()
            @logger.warn("Attribute '#{k}' not found in model attributes: '#{name}', available: [#{attrs}]", @ln)

      if @_to instanceof Sirius.BaseModel
        # {id: {to: attr}}
        name = @_to.normal_name()
        for k, v of object
          attr = v['to']
          if !attr
            o = JSON.stringify(object)
            throw new Error("Impossible create transformer for #{name}, because in object: #{o}, 'to' key not defined")
          else
            attrs = @_to.get_attributes()
            if attrs.indexOf(attr) == -1
              @logger.warn("Attribute '#{attr}' not found in model attributes: '#{name}', available: [#{attrs}]", @ln)

      @_path = object

      if @_to instanceof Sirius.BaseModel
        new Sirius.Internal.ToModelTransformer(object, @_from, @_to)
      else if @_to instanceof Sirius.View
        new Sirius.Internal.ToViewTransformer(object, @_from, @_to)
      else if Sirius.Utils.is_function(@_to)
        new Sirius.Internal.ToFunctionTransformer(object, @_from, @_to)

    else
      throw new Error("Not all parameters defined for transformer: from: #{@_from}, to: #{@_to}")


  @draw: (object) ->

    logger = Sirius.Application.get_logger()

    logger.debug("Draw Transformer", logger.transformer)

    object





