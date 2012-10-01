suite 'Exceptions', ->

  setup ->
    @x = new CS.Identifier 'x'

  test 'throw', ->
    eq 'throw x', generate new CS.Throw @x
