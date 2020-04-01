#
# Utils class with helpers for the framework
#
class Sirius.Utils
  #
  # @param [Any] maybe - check, that `maybe` is Function
  # @return [Boolean]
  #
  @is_function: (maybe) ->
    Object.prototype.toString.call(maybe) is '[object Function]'
  #
  # @param [Any] maybe - check, that `maybe` is String
  # @return [Boolean]
  #
  @is_string: (maybe) ->
    Object.prototype.toString.call(maybe) is '[object String]'
  #
  # @param [Any] maybe - check, that `maybe` is Array
  # @return [Boolean]
  #
  @is_array: (maybe) ->
    Object.prototype.toString.call(maybe) is '[object Array]'

  #
  # @param [Any] a - check if `a` is Object
  # @return [Boolean] - true, when is object, otherwise return false
  #
  @is_object: (maybe) ->
    a != null && typeof(maybe) == 'object'
  #
  # Upper case first letter in string
  #
  # @example
  #   Sirius.Utils.camelize("abc") // => Abc
  # @return [String]
  @camelize: (str) ->
    str.charAt(0).toUpperCase() + str.slice(1)

  #
  # Underline before upper case
  # @example
  #   Sirius.Utils.underscore("ModelName") // => model_name
  # @return [String]
  @underscore: (str) ->
    str.replace(/([A-Z])/g, '_$1').replace(/^_/,"").toLowerCase()

  # return the version of IE
  # from http://stackoverflow.com/a/21712356/1581531
  # @return [Numeric]
  @ie_version: () ->
    ua = window.navigator.userAgent
    msie = ua.indexOf("MSIE ")
    trident = ua.indexOf("Trident/")

    if msie > 0
      return parseInt(ua.substring(msie + 5, ua.indexOf('.', msie)), 10)

    if trident > 0
      rv = ua.indexOf('rv:')
      return parseInt(ua.substring(rv + 3, ua.indexOf('.', rv)), 10)

    0

  @is_ie9: () ->
    @ie_version() == 9
  #
  # Return function name
  # @param [Function]
  # @return [String]
  @fn_name: (fn) ->
    if @is_function(fn)
      fn.toString().match(/function ([^\(]+)/)[1]
    else
      throw new Error("Need function, given #{typeof fn}")
