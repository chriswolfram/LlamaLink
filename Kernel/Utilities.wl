BeginPackage["ChristopherWolfram`LlamaLink`Utilities`"];

DeclareObject
DeclareFunction

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]


(* DeclareObject *)

DeclareObject[head_, {argPatts___}] :=
	(
		head::inv = "Invalid arguments `1` for expression with head `2`.";
		head::prop = "`1` expression called with unknown accessor `2`";
		objectArgumentsMatchQ[head][argPatts] := True;
		objectArgumentsMatchQ[head][___] := False;
		head[args___] /; !objectArgumentsMatchQ[head][args] :=
			(
				Message[head::inv, {args}, head];
				Failure["Invalid"<>ToString[head], <|
					"MessageTemplate" :> head::inv,
					"MessageParameters" -> {{args}, head},
					"Arguments" -> {args},
					"Head" -> head
				|>]
			);
		obj_head[subArgs___] :=
			(
				Message[head::prop, head, {subArgs}];
				Failure["UnknownAccessor", <|
					"MessageTemplate" :> head::prop,
					"MessageParameters" -> {head, {subArgs}},
					"Object" -> obj,
					"Arguments" -> {subArgs}
				|>]
			)
	)
	
DeclareObject[head_, argPatt_] :=
	DeclareObject[head, {argPatt}]


(* DeclareFunction *)

applyImplementation[impl_, {_[args___], opts_}] :=
	With[{listOpts = List@@opts},
		impl[args, listOpts]
	]

DeclareFunction[name_, impl_, nSpec_, assoc_:<||>] :=
	(
		name::invargs = "Invalid arguments passed to function `1`: `2`.";
		
		name[args___] :=
			With[{res = ArgumentsOptions[name[args], nSpec, Join[<|"Head"->HoldComplete|>, assoc]]},
				If[FailureQ[res], res, applyImplementation[impl, res]]
			];
		
		impl[args___, opts_] :=
			Failure["InvalidArguments", <|
				"MessageTemplate" :> name::invargs,
				"MessageParameters" -> {name, HoldForm[{args}]},
				"Arguments" :> {args},
				"Options" :> opts
			|>]
	)


End[];
EndPackage[];