Rebol [
    Title: {LOOP Dialect}

    Description: {
        This is a beginning on the missing (and often requested) range-based
        "Loop Dialect".  It allows one to write things like:

            >> loop x [1 thru 3] [print x]
            1
            2
            3

        Though it is a large design space for a dialect, that seems like a
        basic good start.  Using the words TO and THRU consistent with
        PARSE is a starting example of how such a dialect could seek to
        present a coherent mindset that would help Rebol/Red programmers
        use their early knowledge to apply later.

        (This contrasts with other proposals that have tried to mimic other
        languages with [1 .. 3] or similar; and it's possible to support
        both if it ultimately turns out to be necessary.)

        Note that it's not possible to write good non-native loop wrappers due
        to a blocking and high-priority bug ATM:

            http://issue.cc/r3/539

        Which is a fancy way of saying "these are all broken".  The moment
        you try to return out of the body of a loop, it will just terminate
        the loop and not return from the calling context.

        @earl says he'll be fixing it.  :-)

            http://chat.stackoverflow.com/transcript/message/21300414#21300414

        In the meantime, these can be experimented with.  They should be
        rewritten as natives either way.

        A non-destructive /REVERSE is a likely important option to be
        added to any iterator that can support it...although the range dialect
        will not be able to do so efficiently if it depends on an imperative
        generator (unless the generator can be run in reverse?)
    }
]



; This dialect has not been designed yet, so we just assume it's [X to Y]
; or [X thru Y].  A /REVERSE option is very desirable but may be
; technically difficult to implement in the general case.  It may offer
; it but throw an error on special "irreversible" generators.  Here for
; a test at the moment

make-looper: closure [
    {Generate a function from a LOOP dialect block, yielding values until NONE}
    spec [block!]
    /reverse
] [
    start: reduce first spec
    finish: reduce last spec
    bump: 1

    case [
        'to = second spec [
            ; only go up TO the number, not THRU it
            -- finish
        ]
        'thru [
            ; leave it alone
        ]
        true [
            do make error! "LOOP only supports TO and THRU now"
        ]
    ]

    state: either reverse finish start
    bump: either reverse -1 1
    final: either reverse start finish
    first-run: true
    all-done: state >= final

    func [] [
       if all-done [
           return none
       ]
       temp: state
       if state >= final [
           all-done: true
       ]
       state: state + bump
       return temp
    ]
]



; @GreggIrwin suggested that he thought LOOP was the best foundational name
; for a "looping construct" (vs. FOR).  After thinking about it, @HostileFork
; came to agree.  Consider:
;
;     for x [1 to 10] [print x]
;
; That doesn't have a very clear name for those not-steeped in programing
; history.  The not-used-very-often LOOP construct has a name that's nearly
; as short and doesn't carry that baggage:
;
;     loop x [1 to 10] [print x]
;
; Calling it the "Loop Dialect" vs. the "For Dialect" also makes more sense.
; So stealing the current "loop" from its barely-used current "do this body
; exactly N times" is a worthwhile cost.
;
; The non-meaningful point of terminological distinction (as previously set by
; cases like REPEAT) is not carried forward.  If you wish to not have a LOOP
; variable set, use LOOP but supply a none! value:
;
;     loop # [1 to 10] [print "no loop variable"]
;

loop: func [
    {Run a body of code for every value in a LOOP dialect}
    'word [word! none!] {Variable for value (or # for #[none!] if not needed)}
    spec [block!]
    body [block!]
    /reverse
    /local fun
] [
    if word [set/any quote word-original: get/any word]
    looper: either reverse [make-looper/reverse spec] [make-looper spec]
    also (
        while [not none? either word [set/any word looper] [looper]]
            body
    ) (
        if word [set/any word :word-original]
    )
]



; With the decision to name the "Loop Dialect" vs. calling it the "For Dialect"
; the name FOR became free for its traditional construct.  Which is good
; because C-FOR is a doubly awkward name.  This should probably stay
; implemented as a Mezzanine despite the inefficiency; because supporting
; such a construction is more of a "showcase of what's possible for people
; holding onto the past" than it is a construct which is terribly
; interesting for usage in long-term Rebol programming.
;
; http://chat.stackoverflow.com/transcript/message/15915182#15915182
; http://issue.cc/r3/884

for: func [
    {Execute a "C-style" FOR loop with an initialization, test, and step}
    init [block!]
    test [block!]
    step [block!]
    body [block!]
    /local out
] [
    init: context init

    while bind/copy test init
        bind compose/deep [
            set/any 'out (to paren! body)
            (step)
        ] init

    get/any 'out
]



; "FOREACH" is bad as a name; it's hard to scan, and given that it's a
; non-word the eye often has the word "REACH" jump out of it.  FOR-EACH
; solves the problem at the cost of introducing a hyphen.  On the downside
; of the hyphen, it's long and EACH is accepted fairly standalone in systems
; like jQuery and shorter to type, plus distancing from the word FOR which
; sounds very "old" and not intrinsically meaningful standalone is good.
;
; On the other hand, there is an important complementary routine MAP-EACH
; which uses the same -EACH style accessor to a different effect by gathering
; the results of each evaluation and storing it into a block.
;
; With several examples studied, including EVERY which was panned for
; shorter, known well by its name in systems like jQuery, and given the
; distancing from "FOR" makes more sense to be using.  Other possibilites
; for the word would be FOR-EACH which has the disadvantage of being
; hyphenated.  EVERY might be edgy and a little more unique, but in trying
; that out a while I found myself not really liking it.  (Also EACH can
; abbreviate naturally as EA in Rebmu; seeing EV gets confused with EVEN?)
;
; With support for a none! type, you could write:
;
;     for-each # [a b c] [print "No loop variable"]
;
; ...as a shorter version of something more verbose like:
;
;     loop # [1 to (length? [a b c])] [print "No loop variable"]
;
; At present FOR-EACH does not support that, but it could be useful and a
; consistent point of learnability with LOOP.  The name for-each is
; available also but is hyphenated making it a little "thorny" although
; it may be okay; trying different things.

for-each: :lib/foreach
foreach: does [do make error! "foreach is now FOR-EACH"]



; "FORALL" is a hard one to name, and actually a difficult one to get
; one's head around in the first place.  It combined the weirdness of
; REPEAT with the idea of modifying the series variable itself in the
; body of the loop.
;
;     >> x: [1 2 3 4] forall x [probe x]
;     [1 2 3 4]
;     [2 3 4]
;     [3 4]
;     [4]
;
; That raises mysterious questions about what the value would be at the end
; of the iteration...or if that would be different if you broke out of the
; loop?  The puzzling behaviors have been a source of confusion and apparently
; changed between versions due to problems.
;
; But it is useful, mostly because it lets you modify the series as you
; go and then touch up the series position, letting the construct
; continue to move you.  This is similar to iterators in other languages,
; and I was tempted to call it "ITERATE".  But that is wordy and the idea
; of moving through a series one step at a time helps give you a clue that
; in any given step you can change the state.  It's a shorter name, and
; "single-stepping" is what we'll try for now.  STEP might collide with
; a variable that was recording what step you were in during a process,
; but the language is no stranger to stealing words that you might
; overwrite and use LIB/STEP if you do.
;
; Using the trick of passing in a literal NONE can be similar here;
; spun differently.  Instead of passing a none for the variable to be used
; in the loop, you can optionally pass it in for the *series to be iterated*.
; If none, it will assume you mean the variable already contains the
; series, set to the position you want to start stepping from.

forall: does [do make error! "forall is now achieved via STEP"]

;-- Note: REPEAT becomes what used to be UNTIL

; CAN HANDLE BREAK AS WRITTEN BUT UNSAFE W.R.T. RETURN

step: function [
    {Advance a series variable one step at a time until the end is reached.}
    'word [word!]
        {Word whose value holds the series position during each step}
    series [series! none!]
        {Series to begin iterating or NONE! (#) if 'word is that series!}
    body [block!]
        {Code to execute on each step}
] [
    set/any quote original-value: get/any word
    either series [
        set word series ; we know it can only be NONE! or a SERIES...
    ] [
        unless series? :original-value [
            do make error! {No SERIES to STEP but 'WORD value is not a SERIES!}
        ]
        set word original-value
    ]
    also (
        while [not tail? get word] compose [
            (body)
            unless series? get word [
                do make error!
                {Value in WORD after STEP was not a SERIES!}
            ]
            set word next get word
        ]
    ) (
        set/any word :original-value
    )
]
