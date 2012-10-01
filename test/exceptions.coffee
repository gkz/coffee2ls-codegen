suite 'Exceptions', ->

  setup ->
    @x = new CS.Identifier 'x'
    @y = new CS.Identifier 'y'
    @z = new CS.Identifier 'z'
    @e = new CS.Identifier 'e'

  test 'throw', ->
    eq 'throw x', generate new CS.Throw @x

  test 'try catch', ->
    eq 'try\n  x\ncatch e\n  y', generate new CS.Try @x, @e, @y
    eq 'try\n  x\ncatch e', generate new CS.Try @x, @e
    eq 'try\n  x\ncatch', generate new CS.Try @x

  test 'finally', ->
    eq 'try\n  x\ncatch e\n  y\nfinally\n  z',
      generate new CS.Try @x, @e, @y, @z
