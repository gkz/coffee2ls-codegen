suite 'Interpolations', ->

  test 'simple interpolations', ->
    eq '"ab"'          , generate new ConcatOp (new CSString 'a'), new CSString 'b'
    eq '"a#{b}"'       , generate new ConcatOp (new CSString 'a'), new Identifier 'b'
    eq '"#{a}b"'       , generate new ConcatOp (new Identifier 'a'), new CSString 'b'
    eq '"#{a}#{b}"'    , generate new ConcatOp (new Identifier 'a'), new Identifier 'b'
    eq '"aab"'         , generate new ConcatOp (new CSString 'a'), new ConcatOp (new CSString 'a'), new CSString 'b'
    eq '"#{a}ab"'      , generate new ConcatOp (new Identifier 'a'), new ConcatOp (new CSString 'a'), new CSString 'b'
    eq '"a#{a}b"'      , generate new ConcatOp (new CSString 'a'), new ConcatOp (new Identifier 'a'), new CSString 'b'
    eq '"aa#{b}"'      , generate new ConcatOp (new CSString 'a'), new ConcatOp (new CSString 'a'), new Identifier 'b'
    eq '"#{a}#{a}b"'   , generate new ConcatOp (new Identifier 'a'), new ConcatOp (new Identifier 'a'), new CSString 'b'
    eq '"#{a}a#{b}"'   , generate new ConcatOp (new Identifier 'a'), new ConcatOp (new CSString 'a'), new Identifier 'b'
    eq '"a#{a}#{b}"'   , generate new ConcatOp (new CSString 'a'), new ConcatOp (new Identifier 'a'), new Identifier 'b'
    eq '"#{a}#{a}#{b}"', generate new ConcatOp (new Identifier 'a'), new ConcatOp (new Identifier 'a'), new Identifier 'b'
