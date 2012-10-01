suite 'Switch', ->

  setup ->
    @a = new CS.Identifier 'a'
    @b = new CS.Identifier 'b'
    @c = new CS.Identifier 'c'

  test 'basic switch', ->
    eq 'switch a\ncase b\n  c',
      generate new CS.Switch @a, [new CS.SwitchCase @b, @c]
    eq 'switch a\ncase b\n  c\ncase c\n  b',
      generate new CS.Switch @a, [
        new CS.SwitchCase @b, @c
        new CS.SwitchCase @c, @b
      ]

  test 'switch with alternate', ->
    eq 'switch a\ncase b\n  c\ndefault\n  a',
      generate new CS.Switch @a, [new CS.SwitchCase @b, @c], @a

  test 'switch without expression', ->
    eq 'switch\ncase b\n  c',
      generate new CS.Switch null, [new CS.SwitchCase @b, @c]

  test 'switch case with multiple conditions', ->
    eq 'switch a\ncase b, c\n  a',
      generate new CS.Switch @a, [new CS.SwitchCase [@b, @c], @a]

  test 'switch with it all', ->
    eq 'switch\ncase b, a\n  c\ncase c\n  b\ndefault\n  c',
      generate new CS.Switch null, [
        new CS.SwitchCase [@b, @a], @c
        new CS.SwitchCase @c, @b
      ], @c
