suite 'Loop, Ranges, and Slices', ->

  setup ->
    @zero = new CS.Int 0
    @one = new CS.Int 1
    @two = new CS.Int 2

    @true = new CS.Bool true

    @x = new CS.Identifier 'x'
    @y = new CS.Identifier 'y'
    @xs = new CS.Identifier 'xs'

  test 'simple range', ->
    eq '[1 to 2]', generate new CS.Range true, @one, @two
    eq '[1 til 2]', generate new CS.Range false, @one, @two

  test 'simple slice', ->
    eq 'x[1 to 2]', generate new CS.Slice @x, true, @one, @two
    eq 'x[1 til 2]', generate new CS.Slice @x, false, @one, @two

  test 'for in loop', ->
    eq 'for x in xs\n  x',
      generate new CS.ForIn @x, null, @xs, @one, null, @x
    eq 'for x, y in xs\n  x',
      generate new CS.ForIn @x, @y, @xs, @one, null, @x
    eq 'for x in xs by 2\n  x',
      generate new CS.ForIn @x, null, @xs, @two, null, @x
    eq 'for x in xs when true\n  x',
      generate new CS.ForIn @x, null, @xs, @one, @true, @x
    eq 'for x, y in xs by 2 when true\n  x',
      generate new CS.ForIn @x, @y, @xs, @two, @true, @x

  test 'for in loop with range target', ->
    eq 'for x from 1 to 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range true, @one, @two), @one, null, @x
    eq 'for x from 1 til 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range false, @one, @two), @one, null, @x
    eq 'for x to 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range true, @zero, @two), @one, null, @x
    eq 'for x til 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range false, @zero, @two), @one, null, @x

  test 'for of loop', ->
    eq 'for x of xs\n  x',
      generate new CS.ForOf false, @x, null, @xs, null, @x
    eq 'for own x of xs\n  x',
      generate new CS.ForOf true, @x, null, @xs, null, @x
    eq 'for x, y of xs\n  x',
      generate new CS.ForOf false, @x, @y, @xs, null, @x
    eq 'for x of xs when true\n  x',
      generate new CS.ForOf false, @x, null, @xs, @true, @x
    eq 'for own x, y of xs when true\n  x',
      generate new CS.ForOf true, @x, @y, @xs, @true, @x

  test 'for loops with different bodies', ->
    eq 'for x in xs\n  void',
      generate new CS.ForIn @x, null, @xs, @one, null
    eq 'for x in xs\n  x\n  y',
      generate new CS.ForIn @x, null, @xs, @one, null, new CS.Block [@x, @y]

  test 'while loop', ->
    eq 'while true\n  x', generate new CS.While @true, @x

  test 'break', ->
    eq 'break', generate new CS.Break()

  test 'continue', ->
    eq 'continue', generate new CS.Continue()
