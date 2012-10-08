suite 'Function Application', ->

  setup ->
    @f = new CS.Identifier 'f'
    @a = new CS.Identifier 'a'
    @b = new CS.Identifier 'b'

  test 'function application against implicit object', ->
    eq 'f {\n  a: b\n  b: a\n  f: a\n}',
      generate new CS.FunctionApplication @f, [
        new CS.ObjectInitialiser [
          (new CS.ObjectInitialiserMember @a, @b),
          (new CS.ObjectInitialiserMember @b, @a),
          (new CS.ObjectInitialiserMember @f, @a)
        ]
      ]

  test 'do/let op', ->
    eq 'let a = b\n  b', generate new CS.DoOp new CS.Function [
        new CS.DefaultParam @a, @b
      ], new CS.Block [@b]
    eq 'let a\n  void', generate new CS.DoOp new CS.Function [@a]
    eq 'do ->', generate new CS.DoOp new CS.Function []
    eq 'do a', generate new CS.DoOp @a

  test 'access on implicit call', ->
    eq 'f a.b', generate new CS.FunctionApplication @f, [
        new CS.MemberAccessOp @a, 'b'
      ]

  test 'no arguments', ->
    eq 'f!', generate new CS.FunctionApplication @f, []
