suite 'Other Literals', ->

  test 'undefined -> void', ->
    eq 'void', generate new CS.Undefined()

  test 'booleans', ->
    eq 'true', generate new CS.Bool true
    eq 'false', generate new CS.Bool false
