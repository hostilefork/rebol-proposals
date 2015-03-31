Rebol [
    Title: "MATH - Expression evaluator"
    Author: "Gabriele Santilli"
    Homepage: http://www.rebol.org/ml-display-message.r?m=rmlYHSK

    Description {
        A frequent complaint by users is that Rebol does not obey
        "mathematical precedence" (as if languages had a consensus...)
        @hostilefork argues that perhaps the reason that people 
        evaluating a language are so frightened of not having the
        multiplications run before the additions (without parens)
        is because languages are so inconsistent that it seems like
        one thing they can take for granted.

        In soliciting an evaluator -- any evaluator -- that did a
        semi-convincing job of looking like any random JavaScript or
        C or Modula or what-have-you... @hostilefork asked the SO chat
        to come up with SOMETHING that ran multiplications before the
        additions.  @kealist dug up this one by Gabrielle Santilli
        from way back in 2001 on:

            Amiga Group Italia sez. L'Aquila 
            http://www.amyresource.it/AGI/

        Anything is a start, and as he says in the comments:
        "FEEL FREE TO IMPROVE THIS".  It's now corrected to not
        use caret in order to not run afoul of caret escaping...
        but people should keep using it to see if it is convincing
        to use for "mathematical purposes".  Random rules that 
        throw curveballs into the compositional model aren't 
        going to make any Rebol/Red programmers happy, so the bar
        is probably "don't absolutely hate it" and then it might
        be serving the purpose.

        Renaming this kind of thing MATH is an idea that may have 
        originated from @dockimbel (@hostilefork called it EXPR,
        Gabrielle called it EVAL)
    }
         
    Comment: {
        Evaluates expressions taking usual operator precedence
        into account.
        1. (...)
        2. - [negation], ! [factorial]
        3. ** [power]
        4. *, /
        5. +, - [subtraction]
    }
]

; A simple iterative implementation; returns 1 for negative
; numbers. FEEL FREE TO IMPROVE THIS!
factorial: func [n [integer!] /local res] [
    if n < 2 [return 1]
    res: 1
    ; should avoid doing the loop for i = 1...
    repeat i n [res: res * i]
]

expression-parser: make object! [
    slash: to-lit-word first [ / ]
    expr-val:
    expr-op: none
    expression: [
        term (expr-val: term-val)
        any [
            ['+ (expr-op: 'add) | '- (expr-op: 'subtract)]
            term (expr-val: compose [(expr-op) (expr-val) (term-val)])
        ]
    ]
    term-val:
    term-op: none
    term: [
        pow (term-val: power-val)
        any [
            ['* (term-op: 'multiply) | slash (term-op: 'divide)]
            pow (term-val: compose [(term-op) (term-val) (power-val)])
        ]
    ]
    power-val: none
    pow: [
        unary (power-val: unary-val)
        opt ['** unary (power-val: compose [power (power-val) (unary-val)])]
    ]
    unary-val:
    pre-uop:
    post-uop: none
    unary: [
        (post-uop: pre-uop: [])
        opt ['- (pre-uop: 'negate)]
        primary
        opt ['! (post-uop: 'factorial)]
        (unary-val: compose [(post-uop) (pre-uop) (prim-val)])
    ]
    prim-val: none
    ; WARNING: uses recursion for parens.
    primary: [
        set prim-val [number! | word!]
      | set prim-val paren! (prim-val: translate to-block :prim-val)
    ]
    translate: func [expr [block!] /local res recursion] [
        ; to allow recursive calling, we need to preserve our state
        recursion: reduce [
            :expr-val :expr-op :term-val :term-op :power-val :unary-val
            :pre-uop :post-uop :prim-val
        ]
        res: if parse expr expression [expr-val]
        set [
            expr-val expr-op term-val term-op power-val unary-val
            pre-uop post-uop prim-val
        ] recursion
        res
    ]
    set 'math func [expr [block!] /translate] [
        expr: self/translate expr
        either translate [expr] [do expr]
    ]
]
