
# A class which implement collection interface.
# You might use it as alternative standard javascript arrays.
#
# @example
#
#   class MyModel extends Sirius.BaseModel
#     @attrs: ["id"]
#
#
#  myModel = new MyModel({"id" : 1}
#  myCollection.add(myModel)
#  myCollection.add(new MyModel({"id" : 2})
#  myCollection.add(new MyModel({"id" : 3})
#
#  myCollection.index(myModel) # => 0
#  myCollection.find("id", 1)  # => MyModel Instance
#  myCollection.find("id", 1)  # => [ MyModel Instances ]
#  myCollection.filter( (model) -> model.get("id") > 2 ) # => [ MyModel Instances ]
#  myCollection.first() # => first MyModel instance
#  myCollection.last()  # => last MyModel instance
#
#
#  myCollection.size() # => 3
#  myCollection.length # => 3 // as property
#
#  @note for listen changes in collection use `subscribe` method
#
# Indexes
#
# Sirius.Collection support indexes. For create index you might pass field name for model:
#
# @example
#
#   mICollection = new Sirius.Collection(MyModel, [], { index: ["id"] }
#
# This increases the search speed, in comparison with default search.
#
# @note index fields with unique values.
#
class Sirius.Collection
  @_EVENTS = ['add', 'remove']
  #
  # @param klass [T <: Sirius.BaseModel] - model class for all instances in collection
  # @param options [Object] - with keys necessary
  # @attr index [Array<String>] - fields for index
  constructor: (klass, options = {}) ->
    if klass.__super__.__name isnt 'BaseModel'
      throw new Error("Collection must be used only with `BaseModel` inheritor")
    @_array = []
    @logger = Sirius.Application.get_logger()
    # klasses, options

    @_klass = klass
    @_type  = Sirius.Utils.fn_name(klass)

    @_indexes = options['index'] || []
    if @_indexes.length > 0
      # check that field name is exist and generate additional object
      attrs = klass::attrs().map (attr) ->
        if Sirius.Utils.is_object(attr)
          Object.keys(attr)[0]
        else
          attr


      @_indexes.forEach (field) ->
        if attrs.indexOf(field) == -1
          throw new Error("Collection: field #{field} from indexes: [#{@_indexes}] not exist in #{@_type}")

      # i save models into array
      # index is a hash structure
      # with pairs: field_name : array_index
      # [ Model[id:100, title: some_title#1], Model[id:200, title: title#2], Model[id:300, title: title#3] ]
      # in array: [0, 1, 2]
      #
      # and create index for `id`:
      # index_id: {100 => 0, 200 => 1, 300 => 2}
      #
      @_indexes.forEach (field) =>
        @logger.debug("create index for #{field} field in #{@_type}", @logger.collection)
        @["index_#{field}"] = {}


    @_subscribers = {}
    for e in @constructor._EVENTS
      @_subscribers[e] = []

    @length = 0


  #
  # alias for #add
  # @param model [T <: Sirius.BaseModel]
  # @return [Void]
  push: (model) ->
    @add(model)


  # add model into collection
  # @param model [T <: Sirius.BaseModel]
  # @return [Void]
  add: (model) ->
    @_add(model)
    return

  # @nodoc
  # @private
  _add: (model) ->
    type = Sirius.Utils.fn_name(model.constructor)
    if @_type isnt type
      msg = "Require `#{@_type}`, but given `#{type}`"
      @logger.error("Collection: #{msg}", @logger.collection)
      throw new Error(msg)
    @_array.push(model) #maybe it's a hash ? because hash have a keys, and simple remove, but need a unique id

    # index
    if @_indexes.length > 0
      @_indexes.forEach (field) =>
        @["index_#{field}"][model.get(field)] = @length

    @length++

    @_gen('add', model)

  # remove model from collection
  # @param [T <: Sirius.Model]
  # @return [Void]
  remove: (other) ->
    inx = @index(other)
    if inx != null
      @_array.splice(inx, 1)
      @_gen('remove', other)
      @length--

      # need rebuild index
      if @_indexes.length > 0
        @_indexes.forEach (field) =>
          delete @["index_#{field}"][other.get(field)]
          fields = Object.keys(@["index_#{field}"])
          fields.filter( (x) => @["index_#{field}"][x] > inx ).map (x) =>
            z = @["index_#{field}"][x]
            @["index_#{field}"][x] = z - 1


    return

  #
  # Return index of model in collection or null, if not found
  # @param model [T <: Sirius.BaseModel]
  # @return [Numeric | null]
  index: (other) ->
    inx = null
    for model, i in @_array when model.compare(other) then inx = i
    inx

  #
  # find model by key with value
  # @param key [String] - attribute
  # @param value [Any] - actual value
  # @return [Model | null]
  find: (key, value) ->
    @find_all(key, value)[0] || null

  #
  # find all models by key with value
  # @param key [String] - attribute
  # @param value [Any] - actual value
  # @return [Array<Model>]
  find_all: (key, value) ->
    if @_indexes.length > 0 && @_indexes.indexOf(key) != -1
      [@_array[@["index_#{key}"][value]]] # find first for index is ok, because index is unique
    else
      for model in @_array when model.get(key) == value then model

  #
  # filter collection with `fn`, which must return boolean
  # @param fn [Function]
  # @return [Array<Model>]
  filter: (fn = ->) ->
    for model in @_array when fn.call(null, model) then model

  #
  # Iterate over collection with function
  # @param fn [Function]
  each: (fn = ->) ->
    for model in @_array then fn.call(model)

  # return first element in collection
  # @return [Model]
  first: () ->
    @_array[0]

  # return last element in collection
  # @return [Model]
  last: () ->
    @_array[@_array.length - 1]

  # return actual collection
  # @return [Array<Model>]
  all: () ->
    @_array

  # Clear the collection
  clear: () ->
    @length = 0
    @_array = []
    # remove all from index
    if @_indexes.length > 0
      @_indexes.forEach (field) =>
        @["index_#{field}"] = {}

  # @alias collect
  map: (f) ->
    @collect(f)

  # Apply given method for each element in collection and return result array
  collect: (f) ->
    @_array.map(f)

  # Get first element by conditional
  #
  # @example
  #   col = new Sirius.Collection(Model)
  #   result = col.takeFirst((model) -> model.name() == 'some-name')
  #
  takeFirst: (f) ->
    result = null
    for e in @_array
      if f(e)
        result = e
        break
    result

  # @return [Numeric] size of collection
  size: () ->
    @_array.length

  from_json: (json) ->
    j = JSON.stringify(json)
    if Sirius.Utils.is_array(j)
      for jj in j
        @_array.push(@_klass.from_json(jj))
        @length++
    else
      @_array.push(@_klass.from_json(json))
      @length++
    @

  # convert collection to json
  # @return [JSON]
  to_json: () ->
    z = for e in @_array then e.to_json()
    JSON.parse(JSON.stringify(z))

  #
  #
  # @param [String] - event name for subscribing [add, remove]
  # @param [String|Function] - when it function, then when event will be occurred, then it
  # call given function, when it event (it's should be custom event name) it will be fired.
  #
  # @example
  #
  #
  #   myCollection.subscribe('add', (model) -> console.log('upd'))
  #   myCollection.subscribe('add', 'my_collection:update')
  #   # in routes
  #   'my_collection:update': (event, model) ->
  #     console.log('custom upd')
  #
  #   myCollection.add(new MyMode())
  #   # will be
  #   # print in console: 'upd' and 'custom upd'
  #
  # @return [Void]
  subscribe: (event, fn_or_event) ->
    if @constructor._EVENTS.indexOf(event) == -1
      throw new Error("For 'subscribe' method available only [#{@constructor._EVENTS}], but given '#{event}'")

    if Sirius.Utils.is_string(fn_or_event) or Sirius.Utils.is_function(fn_or_event)
      @logger.info("Collection: Add new subscriber for '#{event}' event", @logger.collection)
      @_subscribers[event].push(fn_or_event)
    else
      throw new Error("Second parameter for 'subscribe' method must be Function or String, but '#{typeof(fn_or_event)}' given")

    return

  # @private
  # @nodoc
  _gen: (event, args...) ->
    subscribers = @_subscribers[event]
    Sirius.Application.get_adapter().and_then (adapter) ->
      for subsriber in subscribers
        if Sirius.Utils.is_string(subsriber)
          adapter.fire(document, subsriber, args...)
        else
          subsriber.apply(null, args)



