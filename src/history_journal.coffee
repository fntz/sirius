
class Sirius.Internal.HistoryJournal
  constructor: (@setup) ->
    @_state = []

  hash: () ->
    window.location.hash

  current: () ->
    window.location.hash

  origin: () ->
    window.location.origin

  pathname: () ->
    pathname = window.location.pathname
    pathname = "/" if pathname == ""
    pathname

  write: (data, title, url) ->
    if @setup.has_push_state_support
      history.pushState(data, title, url)
    else
      history.replaceState(data, title, url)
    @_state.push([data, title, url])

