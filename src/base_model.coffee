
###



###

class BaseModel
###

###
  attrs: () ->
    @constructor.attrs

  validators: () ->
    @constructor.validate

  normalize_attrs: () ->
    for a in @constructor.attrs
      do(a) ->
        if typeof(a) is "object"
          Object.keys(a)[0]
        else
          a

  constructor: (obj = {}) ->
    self = @

    @_isValid = false
    @errors = {}
    @attributes = @normalize_attrs()


    for attr in @attrs()
      do(attr) ->
        if typeof(attr) is "object"
          [key, ...] = Object.keys(attr)
          throw new Error("Attributes should have a key and value") if !key
          self["_#{key}"] = attr[key]
        else
          self["_#{attr}"] = null

    if Object.keys(obj).length != 0
      for attr in Object.keys(obj)
        do(attr) ->
          self.set(attr, obj[attr])


  set: (attr, value) ->
    throw new Error("Attribute '#{attr}' not found for current model") if @attributes.indexOf(attr) == -1

    # TODO validate value
    @["_#{attr}"] = value

  get: (attr) ->
    throw new Error("Attribute '#{attr}' not found for current model") if @attributes.indexOf(attr) == -1

    @["_#{attr}"]




