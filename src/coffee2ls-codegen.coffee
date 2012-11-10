do (exports = exports ? this.coffee2ls-codegen = {}) ->

  TAB = '  '
  indent = (code) -> ("#{TAB}#{line}" for line in code.split '\n').join '\n'
  parens = (code) -> "(#{code})"

  formatStringData = (data) ->
    data
      .replace /[\x00-\x1F]|['\\]/g, (c) ->
        switch c
          when '\0' then '\\0'
          when '\b' then '\\b'
          when '\t' then '\\t'
          when '\n' then '\\n'
          when '\f' then '\\f'
          when '\r' then '\\r'
          when '\'' then '\\\''
          when '\\' then '\\\\'
          else
            escape = (c.charCodeAt 0).toString 16
            pad = "0000"[escape.length...]
            "\\u#{pad}#{escape}"
      .replace /\\\\(u[0-9a-fA-F]{4})/, '\\$1'

  formatInterpolation = (ast, options) ->
    switch ast.className
      when "ConcatOp"
        left = formatInterpolation ast.left, options
        right = formatInterpolation ast.right, options
        "#{left}#{right}"
      when "String"
        formatStringData ast.data
      else
        "\#{#{generate ast, options}}"

  needsParensWhenOnLeft = (ast) ->
    switch ast.className
      when 'Function', 'BoundFunction', 'NewOp', 'Class' then yes
      when 'Conditional', 'Switch', 'While', 'ForIn', 'ForOf', 'Block' then yes
      when 'PreIncrementOp', 'PreDecrementOp', 'UnaryPlusOp', 'UnaryNegateOp', 'LogicalNotOp', 'BitNotOp', 'DoOp', 'TypeofOp', 'DeleteOp'
        needsParensWhenOnLeft ast.expression
      when 'FunctionApplication' then ast.arguments.length > 0
      when 'Super', 'Try' then yes
      else no

  eq = (nodeA, nodeB) ->
    for own prop, val of nodeA
      continue if prop in ['raw', 'line', 'column']
      switch Object::toString.call val
        when '[object Object]' then return no unless eq nodeB[prop], val
        when '[object Array]'
          for v, i in val
            return no unless eq nodeB[prop][i], v
        else return no unless nodeB[prop] is val
    yes

  clone = (obj, overrides = {}) ->
    newObj = {}
    newObj[prop] = val for own prop, val of obj
    newObj[prop] = val for own prop, val of overrides
    newObj

  generateArgs = (args, options = {}) ->
    if args.length
      argList = for a, i in args
        arg = generate a, options
        arg = parens arg if ((needsParensWhenOnLeft a) and i + 1 isnt args.length) or (a.className is 'Function' and i is 0)
        arg
      argList.join ', '
    else ''

  genVar = (options, name = 'ref') ->
    i = 0
    ++i while (out = "#{name}#{i or ''}$$") in options.varsTotal
    options.varsTotal.push out
    options.varsFunc.push out
    out

  levels = [
    ['SeqOp'] # Sequence
    ['Conditional', 'ForIn', 'ForOf', 'While'] # Control Flow
    ['FunctionApplication', 'SoakedFunctionApplication'] # Application
    ['AssignOp', 'CompoundAssignOp', 'ExistsAssignOp'] # Assignment
    ['LogicalOrOp'] # Logical OR
    ['LogicalAndOp'] # Logical AND
    ['BitOrOp'] # Bitwise OR
    ['BitXorOp'] # Bitwise XOR
    ['BitAndOp'] # Bitwise AND
    ['ExistsOp'] # Existential
    ['EQOp', 'NEQOp'] # Equality
    ['LTOp', 'LTEOp', 'GTOp', 'GTEOp', 'InOp', 'OfOp', 'InstanceofOp'] # Relational
    ['LeftShiftOp', 'SignedRightShiftOp', 'UnsignedRightShiftOp'] # Bitwise Shift
    ['PlusOp', 'SubtractOp'] # Additive
    ['MultiplyOp', 'DivideOp', 'RemOp'] # Multiplicative
    ['ExpOp', 'ExtendOp']
    ['UnaryPlusOp', 'UnaryNegateOp', 'LogicalNotOp', 'BitNotOp', 'DoOp', 'TypeofOp', 'PreIncrementOp', 'PreDecrementOp', 'DeleteOp'] # Unary
    ['UnaryExistsOp', 'ShallowCopyArray', 'PostIncrementOp', 'PostDecrementOp', 'Spread'] # Postfix
    ['NewOp'] # New
    ['MemberAccessOp', 'SoakedMemberAccessOp', 'DynamicMemberAccessOp', 'SoakedDynamicMemberAccessOp', 'ProtoMemberAccessOp', 'DynamicProtoMemberAccessOp', 'SoakedProtoMemberAccessOp', 'SoakedDynamicProtoMemberAccessOp'] # Member
  ]

  precedence = {}
  do ->
    for ops, level in levels
      for op in ops
        precedence[op] = level

  operators =
    # Binary
    SeqOp: ';'
    LogicalOrOp: '||', LogicalAndOp: '&&'
    BitOrOp: '.|.', BitXorOp: '.^.', BitAndOp: '.&.'
    EQOp: 'is', NEQOp: 'isnt', LTOp: '<', LTEOp: '<=', GTOp: '>', GTEOp: '>='
    InOp: 'in', OfOp: 'of', InstanceofOp: 'instanceof', ExtendsOp: 'extends'
    LeftShiftOp: '.<<.', SignedRightShiftOp: '.>>.', UnsignedRightShiftOp: '.>>>.'
    PlusOp: '+', SubtractOp: '-', MultiplyOp: '*', DivideOp: '/', RemOp: '%',
    ExpOp: '**',
    AssignOp: '=', ExistsAssignOp: '?:=', ExistsOp: '?'
    # Prefix
    UnaryPlusOp: '+', UnaryNegateOp: '-', LogicalNotOp: 'not ', BitNotOp: '~'
    NewOp: 'new ', TypeofOp: 'typeof '
    PreIncrementOp: '++', PreDecrementOp: '--'
    Spread: '...'
    # Postfix
    UnaryExistsOp: '?'
    ShallowCopyArray: '[..]'
    PostIncrementOp: '++'
    PostDecrementOp: '--'
    # Application
    FunctionApplication: ''
    SoakedFunctionApplication: '?'
    # Member
    MemberAccessOp: '.'
    SoakedMemberAccessOp: '?.'
    ProtoMemberAccessOp: '::'
    SoakedProtoMemberAccessOp: '?::'
    DynamicMemberAccessOp: ''
    SoakedDynamicMemberAccessOp: '?'
    DynamicProtoMemberAccessOp: '::'
    SoakedDynamicProtoMemberAccessOp: '?::'


  lsReserved = [
    'it'
    'that'
    'fallthrough'
    'otherwise'
    'where'
    'xor'
    'match'
  ]

  # TODO: DRY this function
  # TODO: ast as context?
  exports.generate = generate = (ast, options = {}) ->
    return '' if not ast?
    needsParens = no
    options.precedence ?= 0
    options.ancestors ?= []
    options.varsTotal ?= []
    options.varsFunc ?= []
    parent = options.ancestors[0]
    parentClassName = parent?.className
    usedAsExpression = parent? and parentClassName isnt 'Block'

    src = switch ast.className

      when 'Program'
        options.ancestors = [ast, options.ancestors...]
        if ast.body? then generate ast.body, options else ''

      when 'Block'
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: 0
        if ast.statements.length is 0 then generate (new Undefined).g(), options
        else
          sep = if parentClassName is 'Program' then '\n\n' else '\n'
          (generate s, options for s in ast.statements).join sep

      when 'Conditional'
        options.ancestors.unshift ast
        options.precedence = 0

        hasAlternate = ast.consequent? and ast.alternate?
        _consequent = generate (ast.consequent ? (new Undefined).g()), options
        _alternate = if hasAlternate then generate ast.alternate, options else ""
        _condition = generate ast.condition, options

        isMultiline =
          _consequent.length > 90 or
          _alternate.length > 90 or
          '\n' in _alternate or
          '\n' in _consequent

        if hasAlternate
          _alternate =
            if isMultiline then "\nelse\n#{indent _alternate}"
            else " else #{_alternate}"
        if not isMultiline and not hasAlternate and not usedAsExpression
          "#{_consequent} if #{_condition}"
        else if isMultiline
          "if #{_condition}\n#{indent _consequent}#{_alternate}"
        else
          "if #{_condition} then #{_consequent}#{_alternate}"

      when 'Identifier'
        if ast.data in lsReserved
          genVar options, ast.data
        else
          ast.data

      when 'Null' then 'null'
      when 'This' then 'this'
      when 'Undefined' then 'void'

      when 'Int'
        absNum = if ast.data < 0 then -ast.data else ast.data
        # if number is a power of two (at least 2^4) or hex is a shorter
        # representation, represent it as hex
        if absNum >= 1e12 or (absNum > 0x90 and 0 is (absNum & (absNum - 1)))
          "0x#{ast.data.toString 16}"
        else
          ast.data.toString 10

      when 'Float' then ast.data.toString 10

      when 'String'
        "'#{formatStringData ast.data}'"

      when 'Bool'
        "#{ast.data.toString()}"

      when 'ArrayInitialiser'
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: precedence.AssignmentExpression
        members_ = (generate m, options for m in ast.members)
        switch ast.members.length
          when 0 then '[]'
          when 1, 2
            for m, i in members_ when i + 1 isnt members_.length
              members_[i] = parens m if needsParensWhenOnLeft ast.members[i]
            "[#{members_.join ', '}]"
          else "[\n#{indent members_.join '\n'}\n]"

      when 'ObjectInitialiser'
        options.ancestors = [ast, options.ancestors...]
        members_ = (generate m, options for m in ast.members)
        switch ast.members.length
          when 0 then '{}'
          when 1 then "{#{members_.join ', '}}"
          else "{\n#{indent members_.join '\n'}\n}"

      when 'ObjectInitialiserMember'
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: precedence.AssignmentExpression
        key_ = generate ast.key, options
        expression_ = generate ast.expression, options
        memberAccessOps = ['MemberAccessOp', 'ProtoMemberAccessOp', 'SoakedMemberAccessOp', 'SoakedProtoMemberAccessOp']
        if eq ast.key, ast.expression
          "#{key_}"
        else if ast.expression.className in memberAccessOps and ast.key.data is ast.expression.memberName
          "#{expression_}"
        else
          "#{key_}: #{expression_}"

      when 'Function', 'BoundFunction'
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: precedence.AssignmentExpression
          varsTotal: options.varsTotal[..]
          varsFunc: []
        parameters = (generate p, options for p in ast.parameters)
        options.precedence = 0
        _body = if !ast.body? or ast.body.className is 'Undefined' then '' else generate ast.body, options
        _paramList = if ast.parameters.length > 0 then "(#{parameters.join ', '}) " else ''
        _block =
          if _body.length is 0 then ''
          else if _paramList.length + _body.length < 100 and '\n' not in _body then " #{_body}"
          else "\n#{indent _body}"
        switch ast.className
          when 'Function' then "#{_paramList}->#{_block}"
          when 'BoundFunction' then "#{_paramList}~>#{_block}"

      when 'AssignOp', 'ExistsAssignOp'
        _op = operators[ast.className]

        if ast.className is 'AssignOp'
          vars = []
          findIds = (node) ->
            switch node.className
              when 'Identifier'
                vars.push node.data
              when 'Rest'
                vars.push node.expression.data
              when 'ObjectInitialiserMember'
                vars.push node.expression.data
              when 'ArrayInitialiser', 'ObjectInitialiser'
                for member in node.members
                  findIds member
            undefined
          findIds ast.assignee

          if vars.length
            allNew = true
            allReassign = true
            for v in vars
              if v in options.varsTotal and v not in options.varsFunc
                allNew = false
              else
                allReassign = false
                options.varsTotal.push v
                options.varsFunc.push v

            if allReassign
              _op = ':='
            else if not allNew
              throw new Error 'mixed reassign and initialisation in destructuring is not currently supported'
        prec = precedence[ast.className]
        needsParens = prec < options.precedence
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        _assignee = generate ast.assignee, options
        _expr = generate ast.expression, options
        "#{_assignee} #{_op} #{_expr}"

      when 'CompoundAssignOp'
        prec = precedence[ast.className]
        needsParens = prec < options.precedence
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        _op = operators[ast.op]
        _assignee = generate ast.assignee, options
        _expr = generate ast.expression, options
        _assg = if ast.op in ['LogicalOrOp', 'LogicalAndOp'] then ':=' else '='
        "#{_assignee} #{_op}#{_assg} #{_expr}"

      when 'SeqOp'
        prec = precedence[ast.className]
        needsParens = prec < options.precedence
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        _left = generate ast.left, options
        _right = generate ast.right, options
        "#{_left}; #{_right}"

      when 'LogicalOrOp', 'LogicalAndOp', 'BitOrOp', 'BitXorOp', 'BitAndOp', 'LeftShiftOp', 'SignedRightShiftOp', 'UnsignedRightShiftOp', 'EQOp', 'NEQOp', 'LTOp', 'LTEOp', 'GTOp', 'GTEOp', 'InOp', 'OfOp', 'InstanceofOp', 'PlusOp', 'SubtractOp', 'MultiplyOp', 'DivideOp', 'RemOp', 'ExistsOp', 'ExpOp', 'ExtendsOp'
        _op = operators[ast.className]
        if ast.className in ['InOp', 'OfOp', 'InstanceofOp'] and parentClassName is 'LogicalNotOp'
          _op = "not #{_op}"
        if not options.inFunctionApplication
          if ast.className is 'LogicalOrOp'
            _op = 'or'
          else if ast.className is 'LogicalAndOp'
            _op = 'and'

        prec = precedence[ast.className]
        needsParens = prec < options.precedence
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        _left = generate ast.left, options
        _left = parens _left if needsParensWhenOnLeft ast.left
        _right = generate ast.right, options
        "#{_left} #{_op} #{_right}"

      when 'ChainedComparisonOp'
        generate ast.expression, options

      when 'UnaryPlusOp', 'UnaryNegateOp', 'LogicalNotOp', 'BitNotOp', 'TypeofOp', 'PreIncrementOp', 'PreDecrementOp', 'Spread'
        _op = operators[ast.className]
        prec = precedence[ast.className]
        if ast.className is 'LogicalNotOp'
          if ast.expression.className in ['InOp', 'OfOp', 'InstanceofOp']
            _op = '' # these will be treated as negated variants
            prec = precedence[ast.expression.className]
          if 'LogicalNotOp' in [parentClassName, ast.expression.className] or 'EQOp' is parentClassName
            _op = '!'
        needsParens = prec < options.precedence
        needsParens = yes if parentClassName is ast.className and ast.className in ['UnaryPlusOp', 'UnaryNegateOp']
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        if ast.className is 'UnaryNegateOp' and ast.expression.className is 'PreDecrementOp'
          "-#{parens generate ast.expression, options}"
        else
          "#{_op}#{generate ast.expression, options}"

      when 'DeleteOp'
        "delete! #{generate ast.expression, options}"

      when 'UnaryExistsOp', 'PostIncrementOp', 'PostDecrementOp'
        _op = operators[ast.className]
        prec = precedence[ast.className]
        needsParens = prec < options.precedence
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        _expr = generate ast.expression, options
        _expr = parens _expr if needsParensWhenOnLeft ast.expression
        "#{_expr}#{_op}"

      when 'NewOp'
        _op = operators[ast.className]
        prec = precedence[ast.className]
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        _ctor = generate ast.ctor, options
        _ctor = parens _ctor if ast.arguments.length > 0 and needsParensWhenOnLeft ast.ctor
        options.precedence = precedence['AssignOp']
        _args = if ast.arguments.length
          " #{ generateArgs ast.arguments, options }"
        else
          ''
        "#{_op}#{_ctor}#{_args}"

      when 'FunctionApplication', 'SoakedFunctionApplication'
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: precedence[ast.className]
          inFunctionApplication: true
        _op = operators[ast.className]
        _fn = generate ast.function, options
        _fn = parens _fn if needsParensWhenOnLeft ast.function
        if ast.className is 'FunctionApplication' and ast.arguments.length is 0 and parentClassName not in ['UnaryExistsOp', 'SoakedMemberAccessOp']
          "#{_fn}!"
        else
          _argList = if ast.arguments.length
            " #{ generateArgs ast.arguments, options }"
          else
            '()'
          if _fn_indented = _fn.match /\n(\s+).*$/
            # reindent _argList for only the lines that are indented
            [matched, spaces] = _fn_indented
            _argList = (line.replace(new RegExp("^#{spaces}"), "#{TAB}#{spaces}") for line in _argList.split '\n').join '\n'
          "#{_fn}#{_op}#{_argList}"

      when 'MemberAccessOp', 'SoakedMemberAccessOp', 'ProtoMemberAccessOp', 'SoakedProtoMemberAccessOp'
        _op = operators[ast.className]
        prec = precedence[ast.className]
        needsParens = prec < options.precedence
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        newline = no
        if ast.expression.className is 'This'
          _expr = '@'
          _op = '' if ast.className is 'MemberAccessOp'
        else
          _expr = generate ast.expression, options
          reg = new RegExp ("\\n\\s*\\.#{ast.memberName}$")
          if ast.raw && ast.raw.match reg
            newline = yes
          else
            _expr = parens _expr if needsParensWhenOnLeft ast.expression
        if newline
          "#{_expr}\n" + indent "#{_op}#{ast.memberName}"
        else
          "#{_expr}#{_op}#{ast.memberName}"

      when 'DynamicMemberAccessOp', 'SoakedDynamicMemberAccessOp', 'DynamicProtoMemberAccessOp', 'SoakedDynamicProtoMemberAccessOp'
        _op = operators[ast.className]
        prec = precedence[ast.className]
        needsParens = prec < options.precedence
        options = clone options,
          ancestors: [ast, options.ancestors...]
          precedence: prec
        if ast.expression.className is 'This'
          _expr = '@'
        else
          _expr = generate ast.expression, options
          _expr = parens _expr if needsParensWhenOnLeft ast.expression
        options.precedence = 0
        _indexingExpr = generate ast.indexingExpr, options

        if ast.className is 'DynamicMemberAccessOp' and ast.indexingExpr.className in ['String', 'Int']
          "#{_expr}#{_op}.#{_indexingExpr}"
        else
          "#{_expr}#{_op}[#{_indexingExpr}]"

      when 'ConcatOp'
        _left = formatInterpolation ast.left, options
        _right = formatInterpolation ast.right, options
        "\"#{_left}#{_right}\""

      when 'Rest'
        options.ancestors = [ast, options.ancestors...]
        _expr = generate ast.expression, options
        "...#{_expr}"

      when 'RegExp', 'HeregExp'
        options.ancestors = [ast, options.ancestors...]
        _symbol = '//'
        _exprs = if ast.className is 'RegExp'
          ast.data
        else
          formatInterpolation ast.expression, options

        _flags = ''
        _flags += flag for flag, state of ast.flags when state

        "#{_symbol}#{_exprs}#{_symbol}#{_flags}"

      when 'DoOp'
        exp = ast.expression
        if exp.className is 'AssignOp' and exp.expression.className is 'Function'
          prec = precedence[ast.className]
          needsParens = prec < options.precedence
          options = clone options,
            ancestors: [ast, options.ancestors...]
            precedence: prec
          "(#{ generate exp, options })(#{ generateArgs exp.expression.parameters, options })"
        else if exp.className is 'Function' and ((exp.body? and exp.body.className isnt 'Undefined') or exp.parameters.length)
          options = clone options,
            ancestors: [ast, options.ancestors...]
            precedence: prec
            varsTotal: options.varsTotal[..]
            varsFunc: []
          _op = 'let '
          parameters = (generate p, options for p in exp.parameters)
          options.precedence = 0
          if exp.body? and exp.body.className isnt 'Undefined'
            _body = generate exp.body, options
          else
            _body = 'void'
          _paramList = if parameters.length > 0 then "#{parameters.join ', '}" else ''
          "#{_op}#{_paramList}\n#{indent _body}"
        else
          _op = 'do '
          prec = precedence[ast.className]
          needsParens = prec < options.precedence
          options = clone options,
            ancestors: [ast, options.ancestors...]
            precedence: prec
          "#{_op}#{generate ast.expression, options}"

      when 'DefaultParam'
        "#{generate ast.param, options} = #{generate ast.default, options}"

      when 'JavaScript'
        "``#{ast.data}``"

      when 'Range', 'Slice'
        options.ancestors = [ast, options.ancestors...]
        _by = ''
        if ast.left and ast.right and ast.className is 'Range'
          left = +(generate ast.left, options)
          right = +(generate ast.right, options)
          if left is left and right is right # NaN check
            if left is right and not ast.isInclusive
                _main = '[]'
          else
            nonLiteral = true
        else ''
        _mid = if ast.isInclusive then 'to' else 'til'
        _left = if ast.left then generate ast.left, options else ''
        _right = if ast.right then generate ast.right, options else ''
        _target = if ast.expression then generate ast.expression, options else ''
        if ast.className is 'Slice'
          _left ?= '0'
          _left = "+#{_left}" if ast.left and ast.left.className is 'String'
          _right = "+#{_right}" if ast.right and ast.right.className is 'String'
          _right = "#{_right} + 1 || 9e9" if _right and _mid is 'to'
          _args = [_left, _right].join ', '
          "#{_target}.slice(#{_args})"
        else
          if _main
            _main
          else if nonLiteral and not _by # hmmm
            firstRef = genVar options
            secondRef = genVar options
            needsParens = true
            "if (#{firstRef} = #{_left}) > (#{secondRef} = #{_right}) then [#{firstRef} #{_mid} #{secondRef} by -1] else [#{firstRef} #{_mid} #{secondRef}]"
          else
            "[#{_left} #{_mid} #{_right}#{_by}]"

      when 'ForIn', 'ForOf'
        options.ancestors = [ast, options.ancestors...]
        type = if ast.className is 'ForIn' then 'in' else 'of'
        _own = if ast.isOwn then 'own ' else ''

        _firstAssg = if ast.valAssignee
            generate ast.valAssignee, options
          else ''

        _secondAssg = if ast.keyAssignee
            generate ast.keyAssignee, options
          else ''

        [_firstAssg, _secondAssg] = [_secondAssg, _firstAssg] if type is 'of'
        _secondAssg = ", #{_secondAssg}" if _secondAssg

        _target = if type is 'in' and ast.target.className is 'Range'
          _mid = if ast.target.isInclusive then 'to' else 'til'
          if ast.target.left.className is 'Int' and ast.target.left.data is 0
            _rangeLeft = ''
          else
            _rangeLeft = "from #{generate ast.target.left, options} "
          _rangeRight = generate ast.target.right, options
          "#{_rangeLeft}#{_mid} #{_rangeRight}"
        else
          "#{type} #{generate ast.target, options}"

        _step = if not ast.step or ast.step.className is 'Int' and ast.step.data is 1
            ''
          else
            " by #{generate ast.step, options}"

        _filter = if ast.filter
            " when #{generate ast.filter, options}"
          else ''

        comprehension = false
        _body = if ast.body
            comprehension = if ast.body.className is 'Block'
              1 is ast.body.statements.length and 'For' isnt ast.body.statements[0].className.slice 0, 3
            else
              ast.body.className not in ['Function', 'BoundFunction'] and 'For' isnt ast.body.className.slice 0, 3
            comprehension &&= usedAsExpression
            generate ast.body, options
          else'void'

        _mainPart = "for #{_own}#{_firstAssg}#{_secondAssg} #{_target}#{_step}#{_filter}"

        if comprehension
          "[#{_body} #{_mainPart}]"
        else
          _output = "#{_mainPart}\n#{indent _body}"
          needsParens = true if usedAsExpression and parentClassName isnt 'AssignOp'
          _output

      when 'While'
        options.ancestors = [ast, options.ancestors...]
        _condition = generate ast.condition, options
        _body = if ast.body then generate ast.body, options else 'void'

        "while #{_condition}\n#{indent _body}"

      when 'Switch'
        options.ancestors = [ast, options.ancestors...]
        _expression = if ast.expression
            " #{generate ast.expression, options}"
          else ''

        output = "switch#{_expression}\n"
        output += (generate c, options for c in ast.cases).join '\n'
        if ast.alternate
          output += "\ndefault\n#{indent generate ast.alternate, options}"
        output

      when 'SwitchCase'
        options.ancestors = [ast, options.ancestors...]
        _conditions = if ast.conditions.length
            (generate c, options for c in ast.conditions).join ', '
          else
            generate ast.conditions, options
        "case #{_conditions}\n#{indent generate ast.consequent, options}"

      when 'Return'
        "return #{generate ast.expression, options}"

      when 'Break'
        'break'

      when 'Continue'
        'continue'

      when 'Throw'
        "throw #{generate ast.expression, options}"

      when 'Try'
        options.ancestors = [ast, options.ancestors...]
        _body = if ast.body then generate ast.body, options else 'void'
        _catchAssg = if ast.catchAssignee
            " #{generate ast.catchAssignee}"
          else ''

        _catchBody = if ast.catchBody
            "\n#{indent generate ast.catchBody, options}"
          else ''
        finallyBody = if ast.finallyBody
            generate ast.finallyBody, options
          else ''
        _finally = if finallyBody
            "\nfinally\n#{indent finallyBody}"
          else ''

        needsParens = true if usedAsExpression
        "try\n#{indent _body}\ncatch#{_catchAssg}#{_catchBody}#{_finally}"

      when 'Super'
        options.ancestors = [ast, options.ancestors...]
        _args = if ast.arguments.length
          "#{ generateArgs ast.arguments, options }"
        else
          '...'
        "super #{_args}"

      when 'Class'
        options.ancestors = [ast, options.ancestors...]

        _s = ''
        _nameAssg = if ast.nameAssignee
            _s = ' '
            generate ast.nameAssignee, options
          else ''

        _parent = if ast.parent
            " extends #{generate ast.parent, options}"
          else ''

        _body = if ast.body
            "\n#{indent generate ast.body, options}"
          else ''

        needsParens = true if usedAsExpression
        if ast.nameAssignee?.className is 'MemberAccessOp'
          "#{_nameAssg} = class#{_parent}#{_body}"
        else
          "class#{_s}#{_nameAssg}#{_parent}#{_body}"

      when 'Constructor'
        _body = generate ast.expression, options
        if ast.expression.className is 'Function'
          _body
        else
          "constructor$$: #{_body}"

      when 'ClassProtoAssignOp'
        options.ancestors = [ast, options.ancestors...]
        _assignee = generate ast.assignee, options
        _expression = generate ast.expression, options
        "#{_assignee}: #{_expression}"

      else
        throw new Error "Non-exhaustive patterns in case: #{ast.className}"

    if needsParens then (parens src) else src
