#
# Utils class with helpers for application
#
class Sirius.Utils
  #
  # @param [Any] a - check, that `a` is a Function
  # @return [Boolean] - true, when is Function, otherwise return false
  #
  @is_function: (a) ->
    Object.prototype.toString.call(a) is '[object Function]'
  #
  # @param [Any] a - check, that `a` is a String
  # @return [Boolean] - true, when is String, otherwise return false
  #
  @is_string: (a) ->
    Object.prototype.toString.call(a) is '[object String]'
  #
  # @param [Any] a - check, that `a` is a Array
  # @return [Boolean] - true, when is Array, otherwise return false
  #
  @is_array: (a) ->
    Object.prototype.toString.call(a) is '[object Array]'
  #
  # Upper case first letter in string
  #
  # @example
  #   Sirius.Utils.camelize("abc") // => Abc
  @camelize: (str) ->
    str.charAt(0).toUpperCase() + str.slice(1)

  #
  # Underline before upper case
  # @example
  #   Sirius.Utils.underscore("ModelName") // => model_name
  @underscore: (str) ->
    str.replace(/([A-Z])/g, '_$1').replace(/^_/,"").toLowerCase()

  # return the version of IE
  # from http://stackoverflow.com/a/21712356/1581531
  @ie_version: () ->
    ua = window.navigator.userAgent
    msie = ua.indexOf("MSIE ")
    trident = ua.indexOf("Trident/")

    if msie > 0
      return parseInt(ua.substring(msie + 5, ua.indexOf('.', msie)), 10)

    if trident > 0
      rv = ua.indexOf('rv:')
      return parseInt(ua.substring(rv + 3, ua.indexOf('.', rv)), 10)

    false

  #
  # Return function name
  # @param [Function]
  # @return String
  @fn_name: (fn) ->
    if @is_function(fn)
      fn.toString().match(/function ([^\(]+)/)[1]
    else
      throw new Error("Need function, given #{typeof fn}")
