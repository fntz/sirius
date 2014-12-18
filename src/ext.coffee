# Source https://gist.github.com/eligrey/384583
if !Object::watch
  Object.defineProperty Object::, "watch",
    enumerable: false
    configurable: true
    writable: false
    value: (prop, handler) ->
      oldval = this[prop]
      newval = oldval
      getter = ->
        newval

      setter = (val) ->
        oldval = newval
        newval = handler(prop, oldval, val)

      if delete this[prop] # can't watch constants
        Object.defineProperty this, prop,
          get: getter
          set: setter
          enumerable: true
          configurable: true

      return

if !Object::unwatch
  Object.defineProperty Object::, "unwatch",
    enumerable: false
    configurable: true
    writable: false
    value: (prop) ->
      val = this[prop]
      delete this[prop] # remove accessors

      this[prop] = val
      return


