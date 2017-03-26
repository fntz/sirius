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

# TODO: ViewToView, ViewToObject, ObjectToView

class Sirius.AbstractTransformer

  constructor: (@_path, @_model, @_view) ->
    @logger = Sirius.Application.get_logger()
    @_ln = @logger.transformer # logger name
    @_register()

  _register: () ->



# @private
# @nodoc
class Sirius.ToViewTransformer extends Sirius.AbstractTransformer
  _register: () ->
    @_model._register_state_listener(@)

# TODO Check that this works for inputs
  _default_via_method: () ->
    (value, selector, view) ->
      view.zoom(selector).render(value).swap()


  fire: (attribute, value) ->
    value = @_path[attribute]

    if value
      @logger.debug("Apply new value for '#{attribute}' for '#{@_view.get_element()}', value: #{value}", @_ln)
      to = value['to']
      via = value['via'] || @_default_via_method()
      via(value, selector, @_view)

# @private
# @nodoc
class Sirius.ToModelTransformer extends Sirius.AbstractTransformer
  _register: () ->
    @_view._register_state_listener(@)

  _default_via_method: () ->
    (value) -> value

  fire: (selector) ->
    value = @_path[selector]
    if value
      to = value['to']
      from = value['from'] || 'text'
      via = value['via'] || @_default_via_method()

      @logger.debug("Apply new value from #{selector} to #{@_model.normalize_name()}.#{to}")

      need = @_view.zoom(selector).fetch_current_value(from)

      @_model.set(via(need))



class Sirius.Transformer
  @_Model :  0
  @_View  :  1
  # TODO JsObject, View2View

  _from: null

  # Sirius.View
  _view: null

  # Sirius.Model
  _model: null

  # hash object
  _path: null

  constructor: (@_model, @_view) ->

  _m: () -> Sirius.Transformer._Model
  _v: () -> Sirius.Transformer._View

  # called implicitly with `via` method in binding
  set_from: (from) ->
    if @_m() == from || @_v() == from
      @_from = from
    else
      throw new Error("Unexpected 'from' option for Transformer, required: Model: #{@_m()} or View: #{@_v()}")

  _from_model: () ->
    @_m() == @_from

  run: (object) ->
    @_path = object

    if @_from_model()
      new Sirius.ToViewTransformer(object, @_model, @_view)
    else
      new Sirius.ToModelTransformer(object, @_model, @_view)

  @draw: (object) ->
    # TODO add validation for to and via methods
    logger = Sirius.Application.get_logger()

    logger.debug("Draw Transformer", logger.transformer)

    object





