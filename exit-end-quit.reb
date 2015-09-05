Rebol [
    Title: {Exit, End, Quit proposal}

    Description {
	The original proposals have been deprecated.
	void and set? are left, but need to go elsewhere.

        http://curecode.org/rebol3/ticket.rsp?id=2200
        http://curecode.org/rebol3/ticket.rsp?id=2181
    }
]


void: func [
    {Evaluates to no value.}
] [
    #[unset!]
]


set?: function [value [any-type!]] [not unset? :value]
