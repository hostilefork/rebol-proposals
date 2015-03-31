Rebol [
    Title: {Comparison Operators Roadmap}

    Description: {
        The many forms and foibles of comparisons have led to the creation
        of invisible hierarchies of strictness in comparison, and mysterious
        behaviors.  For instance--although there is a comparison function
        used by SORT it is not a function that is exposed, and not equivalent
        to lesser?  The function used to trigger a match in SELECT and FIND
        is not any variant of equal? that is exposed.  There are wild
        and unexpected equivalencies in = while what would be conveniences
        are missing.

        This is an attempt to investigate and rethink what should be in the
        box, and what *can* be in the box.  It also attempts to come up
        with good names for things that convey nuance.  There is not much
        use in calling an exposed operator NOT-EQUAL? when it is the same
        as just writing NOT EQUAL?--that would be like calling UNLESS
        IF-NOT.  The ability to inflect a piece of code is lost, so
        NOT-EQUAL? here is reassigned to DIFFERENT?...which has the added
        benefit of not creating a puzzle of whether adding strictness
        creates STRICT-NOT-EQUAL? or NOT-STRICT-EQUAL?.

        There have been attempts to fold more properties into the hierarchy,
        for instance coming up with comparisons that check to see that
        binding is
        For the moment, reprogramming the infix operators is stalled because
        defining infix custom operators is not possible, and many interesting
        comparison operators are not allowed to exist.  This proposal would
        bring more of those symbolic operators to the table:

            http://curecode.org/rebol3/ticket.rsp?id=2206

        Ideas are mentioned for what they could be.
    }
] 


;
; BASIC EQUALITY
;
; Rebol's freedom to use the simple = for equality is very pleasant, but
; has historically also been very puzzling.  Many find its case-insensitivity
; by default to be off-putting.  It seems to be unwilling to compare
; "A" as equal to `first "ABC"` due to characters and strings being different
; types, yet it will let the integer! 1 equal the "float!" (decimal!) 1.0
; It considers the SET-WORD! FoO: equal to the lit-word fOo.
;
; Stranger yet, EQUAL? isn't even what's used to power matching via SELECT
; or FIND:
;
;     >> equal? 'foo quote FoO:
;     == true
;
;     >> select ['foo {Hello}] quote FoO:
;     == "Hello"
;
;     >> equal? <foo> {foo}
;     == true
;
;     >> select [<foo> {Hello}] {foo}
;     == none
;
;     >> select [<foo> {Hello}] <foo>
;     == "Hello"
;
; You want to be able to SELECT [foo: 1] 'foo ... so that might have been a
; reasonable explanation for why EQUAL? was so weird.  But it's not.
;
; This experiment tries to tidy up the default EQUAL? to be better.
;

equal?: function [a b] [
    case [
        ; eliminate the equivalence of all words with same spellings
        ; and only case-insensitively compare spellings of same word types

        all [
            any-word? :a | any-word? :b | not lib/equal? (type? :a) (type? :b)
        ] [
            false
        ]

        ; allow single character strings to pass comparison to a char!.
        ; this change is often requested, and a large stumbling block for
        ; new users (and hard-to-find bug cause for experienced users).
        ;
        ; @earl has voiced belief that this stumbling block is a good thing
        ; for people who "need to know the distinction", whereas @hostilefork
        ; thinks that using == can cover strictness well enough on such
        ; matters.  There are plenty of other opportunities for
        ; users to learn from blocks.  @earl believes it's a slippery slope
        ; to 1 = [1] to say a series of things is equal to a single element
        ; of the thing...while @hostilefork believes it's a spectrum.
        ; It's more like 15 = #{0F}, because you're dealing with a specific
        ; typed series that can only hold that kind of value and isn't
        ; structural.  In any case, like the Plan Minus Four, sometimes a
        ; few strategic compromises yield a better system than "purity"
        ; This tests that, and might as well test the binary issue too.

        all [char? :a | string? :b | tail? next :b] [
            lib/equal? a b/1
        ]

        all [string? :a | char? :b | tail? next :a] [
            lib/equal? a/1 b
        ]

        all [integer? :a | binary? :b | tail? next :b] [
            lib/equal? a b/1
        ]

        all [binary? :a | integer? :b | tail? next :a] [
            lib/equal? a/1 b
        ]

        ; delegate everything else to equal? as it was (for now...)

        true [
            lib/equal? :a :b
        ]
    ]
]

different?: function [a b] [not equal?]

not-equal?: does [do make error! "use DIFFERENT? for not-equal?"]



;
; STRICT EQUALITY AND DIFFERENCE
;
; Strict equality...which enforces case and typing...will not let you get
; away with things like 1.0 = 1 or "A" = #"A", and much less will it
; tolerate different cases of the same type.
;
; However, it throws in an extra curve ball: it checks bindings.
;
;     >> foo: object [x: 10]
;
;     >> bar: object [x: 20]
;
;     >> foo-x: bind 'x foo
;
;     >> bar-x: bind 'x bar
;
;     >> strict-equal? foo-x bar-x
;     == false
;
;     >> find/case reduce [foo-x] bar-x
;     == [x]
;
; This makes it tempting to throw in another level of equality comparison
; that checks bindings (not just of words, but if comparing blocks the
; words within the blocks).  So stricter-than-your-usual-strict.  Call
; that EQUIVALENT? or EQUIV?
;
;     http://curecode.org/rebol3/ticket.rsp?id=1834
;
; It gets hard to name all the versions; and paring them down would be
; welcome.  Adding CASE-EQUAL? to be distinct from STRICT-EQUAL? and
; EQUIV? seems a pain, when == is best thought of as STRICT-EQUAL? and
; it would be nice if STRICT-LESSER? could guide SORT.  So ideally /CASE
; would shift to tie in with /STRICT:
;
;     http://curecode.org/rebol3/ticket.rsp?id=1832
;
; It's hard for this file to make changes that need to be in the codebase...
; but everything is done via SORT/CASE.  This means that STRICT-EQUAL? has
; the semantics of what SORT would do and exposes that inner comparator.
;
; Red currently has << and >> being used for bit-shift (which is interesting
; considering the constant refrain of not bowing-to or looking-like C).
; As adding an extra equals sign makes an equality comparison "stricter",
; it could be more interesting to add another > or < to make the relative
; comparisons stricter.  It would at least be a unique use of the symbols
; helping to build a complete story about how to get access to the
; infix comparator driving what you get with SORT/STRICT
;

strict-not-equal?: does [
    do make error! "strict-different? vs strict-not-equal?"
]

strict-equal?: function [a b] [
    either lib/strict-equal? sort/case reduce [a b] sort/case reduce [b a] [
        ; we sorted and got the same results when we reordered them,
        ; suggesting SORT thought it worthwhile to rearrange them.  We
        ; don't know if sort is stable (no refinement like in Red) so
        ; it doesn't necessarily tell us they're different.  Double
        ; check by falling through to strict-equal as a test

        lib/strict-equal? :a :b
    ] [
        ; sort gave different results, e.g. thought not to rearrange.
        ; that's good enough evidence of /CASE-style equality, right?
        true
    ]
]

strict-different?: function [a b] [
    not strict-equal? :a :b
]

set quote << does [do make error! "<< cannot be infix strict-lesser? yet..."]

strict-lesser?: function [a b] [
    either strict-equal? :a :b [
        false
    ] [
        strict-equal? :a first sort/case reduce [a b]
    ]
]

set quote >> does [do make error! ">> cannot be infix strict-greater? yet..."]

strict-greater?: function [a b] [
    either strict-equal? :a :b [
        false
    ] [
        strict-equal? :b first sort/case reduce [a b]
    ]
]

;-- should be also <<=
strict-lesser-or-equal?: function [a b] [
    either strict-equal? :a :b [
        true
    ] [
        strict-equal? :a first sort/case reduce [a b]
    ]
]

;-- should be also >>=
strict-greater-or-equal?: function [a b] [
    either strict-equal? :a :b [
        true
    ] [
        strict-equal? :b first sort/case reduce [a b]
    ]
]


;
; "SAMENESS"
;
; It is possible to determine if two things are the same, e.g. a modification
; to one will affect the other.  It's hard to say.  You want a short way
; of saying referenecs-same-entity.  It's a little unfortunate to name
; it, but SAME has worked for a while.
;

=?: does [
    do make error "=? is a poor symbol for SAME?, should be ==="
]

; although !=== is a bit long, it follows the formula.  The more equals
; the more you mean it.

distinct?: function [a b] [not same? :a :b]



;
; MATCHING
;
; match? is meant to correspond to the concept of whatever it is that drives
; the behavior of SELECT and FIND so that there is no need to reinvent
; that logic.  Note this is not driven by either equal? or strict-equal?
;
; For this logic we really have no sort heirarchy; there is no lesser or
; greater variant.
;
; As before we want to use a different word than not-match? so we go with
; mismatch? ... ideally it would start with a different letter for Rebmu's
; sake, but there is no decent word for it.  Once again there is a STRICT
; variant at play.
;
; Does this need an infix version?  What might it look like w/symbols open?
; It seems like a good fit for ending in ? because it's often used as
; part of an extra level of query like "is this in the set?"
;

;-- maybe also something like =?
match?: function [a b] [
    true? find reduce [a] :b
]

;-- maybe also something like !=?
mismatch?: function [a b] [
    not match :a :b
]

;-- maybe also something like ==?
strict-match?: function [a b] [
    true? find/case reduce [a] :b
]

;-- maybe also something like !==?
strict-mismatch?: function [a b] [
    not strict-match? :a :b
]


;
; SIMILARITY
;
; "Similarity" is based on the idea of thinking that maybe someone out there
; liked some of the freakishness and would like something that "takes all the
; laxness they knew and loved" from the old equality operators and "turns it
; up to 11":
;
;     >> similar? <tag> "tag"
;     == #[true]
;
;     >> similar? <tag> "<tag>"
;     == #[true]
;
;     >> similar? <tag> "<tag"
;     == #[false]
;
;     >> similar? 12-12-2012 "12-Dec-2012"
;     == #[true]
;
;     >> similar? 12-Dec-2012 "12-12-2012"
;     == #[true]
;
;     >> similar? 12-Dec-2012 "12-13-2012"
;     == #[false]
;
; As weird as it looks, it's actually well-defined (or at least as well
; defined as such a thing could be).  The idea is that it attempts a TO
; conversion on each parameter to the other's type.  If *either* conversion
; can succeed and check as equal, then it says they're at-least-a-bit-related
; and returns TRUE.
;
; I think it might be actually useful if it covers something you actually
; want and you don't care that much about rigor.  The tag and date examples
; are fairly reasonable, as would be the case if you knew you had two words
; of different types...or a string and a word and "close enough" counted.
; Having the behavior wrapped up in a single S? function for Rebmu Code Golf
; where the task inputs and outputs are fixed within limits...it might be
; just what you need in two characters.  :-/
;
; The comparator versions for this are especially twisted, because in
; the conversion matrix what if they disagree?  What if both ways succeed
; yet have different answers?  The only sensible thing to do (if any of
; this is sensible) is to raise an error if that happens as you can't give
; a yes-or-no on that.
;

;-- should be also ~=
similar?: function [a b] [
    temp: try/except [to :a :b] [
        ;-- couldn't turn a into b, how about the reverse?

        temp: try/except [to :b :a] [
            ;-- couldn't do either conversion, they can't be equal?
            assert [not equal? :a :b]
            return false
        ]

        return equal? :temp :b
    ]

    ; turned b into a's type... but were they equal?
    either equal? :a :temp [
        true
    ] [
        ; they weren't equal but don't give up, still try the other way

        temp: try/except [to :b :a] [
            ;-- couldn't do either conversion, they can't be equal?
            assert [not equal? :a :b]
            return false
        ]

        equal? :temp :b
    ]
]

;-- should be also !~=
dissimilar?: function [a b] [
    not similar? :a :b
]

;-- should be also ~==
strict-similar?: function [a b] [
    temp: try/except [to :a :b] [
        ;-- couldn't turn a into b, how about the reverse?

        temp: try/except [to :b :a] [
            ;-- couldn't do either conversion, they can't be equal?
            assert [not strict-equal? :a :b]
            return false
        ]

        return strict-equal? :temp :b
    ]

    ; turned b into a's type... but were they equal?
    either strict-equal? :a :temp [
        true
    ] [
        ; they weren't equal but don't give up, still try the other way

        temp: try/except [to :b :a] [
            ;-- couldn't do either conversion, they can't be equal?
            assert [not strict-equal? :a :b]
            return false
        ]

        strict-equal? :temp :b
    ]
]

;-- should be also !~==
strict-dissimilar?: function [a b] [
    not strict-similar? :a :b
]

make-similar-compare-func: func [comparator [word!]] [
    function [a b] compose/deep [
        set/any quote temp-a: try/except [to :b :a] [void]
        set/any quote temp-b: try/except [to :a :b] [void]
        case [
            all [unset? :temp-a unset? :temp-b] [
                assert [unequal? :a :b]
                false
            ]

            all [set? :temp-a set? :temp-b] [
                result: (get comparator) :temp-a :b
                if result != (get comparator) :a :temp-b [
                    do make error! combine [
                        "Inconsistent conversion comparison case for" ^_
                        replace to-string comparator "equal?" "similar?"
                    ]
                ]
                result
            ]

            set? :temp-a [(get comparator) :temp-a :b]

            set? :temp-b [(get comparator) :a :temp-b]

            true [assert [false]]
        ]
    ]
]

;-- should be also ~<=
lesser-or-similar?: make-similar-compare-func 'lesser-or-equal?

;-- should be also ~>=
greater-or-similar?: make-similar-compare-func 'greater-or-equal?

;-- should be also ~<<=
strict-lesser-or-similar?: make-similar-compare-func 'strict-lesser-or-equal?

;-- should be also ~>>=
strict-greater-or-similar?: make-similar-compare-func 'strict-greater-or-equal?

unset 'make-similar-compare-func
