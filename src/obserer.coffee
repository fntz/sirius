
# hacks for observer when property or text changed into DOM


class Sirius.TextObserver

  MO = window.MutationObserver ||
       window.WebKitMutationObserver ||
       window.MozMutationObserver || null


  constructor: (@clb) ->
    # MutationObserver support in FF and Chrome, but in old ie (9-10) not
    # for support this browser
    # http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-MutationEvent
    # https://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#mutation-observers
    if MO


    else # when null, need register event with routes
      















