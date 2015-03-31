Rebol [
    Title {Short Word Name Reassignments}

    Description {
        Rebol has often been used as a kind of console but it is poor at
        that, and several "shorthands" (as far as T for running test.reb)
        have managed to make it into the language core.  For a general
        purpose language focusing on a literate specification, words like
        LS or CD (which are shorthands or CHANGE-DIR and LIST-DIR) are
        not appropriate. to include.  Q also causes a mysterious problem
        if you type APPEND [X Y Z] Q (or similar) and it seems the
        interpreter crashed with no message.

        Also considering the dynamism of Rebol and what its good at, its
        metaprogramming domain has been too deferent to classic programming
        needs like bitwise operators and such.  These biases have befuddled
        new users and been challenged repeatedly:

            http://curecode.org/rebol3/ticket.rsp?id=1879

            http://curecode.org/rebol3/ticket.rsp?id=2128

        For those who need such semantics, rarely occuring in the core
        DSL/symbolic domains, it's possible to put them in an EXPR or MATH
        like sandbox...along with other things like operator precedence
        which puts multiplication before addition, which are also a sort
        of noise in the core system for implementing dialects.
    }
]

;-- SHELL dialect allows interactive user configuration in a much more
;-- powerful way with a persistent process.  These shorthands are only
;-- appropriate in console builds; and should not wind up in any situation
;-- into which a Rebol/Red engine gets installed

ls: does [do make error! "in user config `ls: :list-dir`"]

cd: does [do make error! "in user config `cd: :change-dir`, as approximation"]

pwd: does [do make error! "in user config `pwd: :what-dir`"]


;-- A classic:
;--
;--     append [a b c] 'd
;--
;-- Time passes, user does another test:
;--
;--     append [w x y] q
;--
;-- Why'd the interpreter crash?  Filing bug report now...

q: does [do make error! "q is deprecated, use QUIT or EXIT"]


;-- Don't know how this one made it in, not even going to give a warning
;-- about its disappearance.

unset 't


;-- A strange pair of abbreviations to pick... why not just use Rebmu?
;-- *everything* is abbreviated!  AP for APPEND!  Imagine the savings...
;-- (No, really.  Imagine.  Why do it halfway?)

dt: does [do make error! "dt abbreviation is deprecated, use DELTA-TIME"]

dp: does [do make error! "dp abbreviation is deprecated, use DELTA-PROFILE"]


;-- Infix bitwise AND is not very useful, and "conditional" AND is the only
;-- infix on the horizon.  INTERSECT is better.
;--
;--     http://curecode.org/rebol3/ticket.rsp?id=1879

&: does [do make error! {No infix bitwise "AND"... use prefix INTERSECT}]


; "Expression Barrier"...an adjusted version of the original proposal that
; wanted to use . and , for that.
;
;     http://curecode.org/rebol3/ticket.rsp?id=2156
;
; While there are actually several functions (especially low-level system ones)
; that can accept an UNSET! value if it is generated as a parameter
; (for instance, TYPE?)... user-written functions will typically choke, as
; will math and series operations.  Dangers would be quoted contexts that
; would pick up the vertical pipe and not evaluate to the UNSET!, on them...as will math and series

|: func [
    {Expression Barrier that returns an Unset value that few operations accept}
] []


; The choice to take this prominent comment-to-end-of-line
; marker and make it mean the same thing as MOD seems unwise.  In NewPath
; this would be the notation for a path that was equivalent to:
;
;     to-path [none none none] => //
;
; http://blog.hostilefork.com/new-path-debate-rebol-red/

set quote // does [do make error! "// deprecated / in non-path, use MODULO"]
