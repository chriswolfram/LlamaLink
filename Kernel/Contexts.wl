BeginPackage["ChristopherWolfram`LlamaLink`Contexts`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Context objects *)

DeclareObject[LlamaContext, {_ManagedObject, _LlamaModel}];


(* Accessors *)

ctx_LlamaModel["RawContext"] := ctx[[1]]
ctx_LlamaModel["Model"] := ctx[[2]]


(* Creating contexts *)

contextDefaultParamsC := contextDefaultParamsC = 
	ForeignFunctionLoad[$LibLlama, "llama_context_default_params", {} -> Values@$ContextParamsStruct];

newContextWithModelC := newContextWithModelC = 
	ForeignFunctionLoad[$LibLlama, "llama_new_context_with_model", {"OpaqueRawPointer", Values@$ContextParamsStruct} -> "OpaqueRawPointer"];

freeC := freeC = 
	ForeignFunctionLoad[$LibLlama,  "llama_free", {"OpaqueRawPointer"} -> "Void"];


DeclareFunction[LlamaContextCreate, iLlamaContextCreate, 1];

iLlamaContextCreate[model_LlamaModel, opts_] :=
	Module[{ptr},
		ptr = newContextWithModelC[model["RawModel"], contextDefaultParamsC[]];
		If[NullRawPointerQ[ptr],
			$Failed,
			LlamaContext[CreateManagedObject[ptr, freeC], model]
		]
	]


End[];
EndPackage[];