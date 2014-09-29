
# hacks for observer when property or text changed into DOM

# #TODO not need create new observer, just subscribe for the currents
#
class Sirius.Observer

  @_observers:   []
  @add_observer: (new_observer) ->
    1

  MO = window.MutationObserver ||
       window.WebKitMutationObserver ||
       window.MozMutationObserver || null


  constructor: (@from_element, @clb = ->) ->
    `var c = function(m){console.log(m);};`
    adapter = Sirius.Application.adapter
    # browser support: http://caniuse.com/#feat=mutationobserver
    # MutationObserver support in FF and Chrome, but in old ie (9-10) not
    # for support this browser
    # http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-MutationEvent
    # https://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#mutation-observers
    if MO
      clb  = @clb
      from = @from_element

      observer = new MO( (mutations) ->
        mutations.forEach (m) ->
          # m have type
          # m have target (from_element)
          # m have oldValue
          # m have attributeName
          clb(adapter.text(from))


      )

      cnf = { childList: true, attributes: true, characterData: true, subtree: false } # FIXME subtree: true

      elems = adapter.get(@from_element) # fixme : all

      observer.observe(elems, cnf)

    else # when null, need register event with routes
      1















