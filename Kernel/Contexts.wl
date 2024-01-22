BeginPackage["ChristopherWolfram`LlamaLink`Contexts`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Context objects *)

DeclareObject[LlamaContext, {_ManagedObject, _List, _LlamaModel}];


(* Accessors *)

ctx_LlamaContext["RawContext"] := ctx[[1]]
ctx_LlamaContext["RawParameters"] := ctx[[2]]
ctx_LlamaContext["Model"] := ctx[[3]]


nCtxC := nCtxC = 
	ForeignFunctionLoad[$LibLlama, "llama_n_ctx", {"OpaqueRawPointer"} -> "UnsignedInteger32"];

nBatchC := nBatchC = 
	ForeignFunctionLoad[$LibLlama, "llama_n_batch", {"OpaqueRawPointer"} -> "UnsignedInteger32"];

ctx_LlamaContext["RawNContext"] := nCtxC[ctx["RawContext"]]

ctx_LlamaContext["RawNBatch"] := nBatchC[ctx["RawContext"]]


(* Parameters *)

paramIndices := paramIndices = PositionIndex[Keys@$ContextParamsStruct][[All,1]]

ctx_LlamaContext["LogitsAll"] := ctx["RawParameters"][[paramIndices["logits_all"]]]


(* Logits *)

getLogitsC := getLogitsC = 
	ForeignFunctionLoad[$LibLlama, "llama_get_logits", {"OpaqueRawPointer"} -> "RawPointer"::["CFloat"]];

getLogitsIthC := getLogitsIthC = 
	ForeignFunctionLoad[$LibLlama, "llama_get_logits_ith", {"OpaqueRawPointer", "Integer32"} -> "RawPointer"::["CFloat"]];

ctx_LlamaContext["RawGetLogits", i_Integer] :=
	RawMemoryImport[getLogitsIthC[ctx["RawContext"], i], {"List", ctx["Model"]["VocabularySize"]}]


(* KV Cache *)

kvCacheSeqRmC := kvCacheSeqRmC = 
	ForeignFunctionLoad[$LibLlama, "llama_kv_cache_seq_rm", {"OpaqueRawPointer", $SeqIDType, $PosType, $PosType} -> "Void"];

ctx_LlamaContext["KVCacheSequenceRemove", seqid_, p0_, p1_] :=
	kvCacheSeqRmC[ctx["RawContext"], seqid, p0, p1]


(* Creating contexts *)

contextDefaultParamsC := contextDefaultParamsC = 
	ForeignFunctionLoad[$LibLlama, "llama_context_default_params", {} -> Values@$ContextParamsStruct];

newContextWithModelC := newContextWithModelC = 
	ForeignFunctionLoad[$LibLlama, "llama_new_context_with_model", {"OpaqueRawPointer", Values@$ContextParamsStruct} -> "OpaqueRawPointer"];

freeC := freeC = 
	ForeignFunctionLoad[$LibLlama,  "llama_free", {"OpaqueRawPointer"} -> "Void"];


DeclareFunction[LlamaContextCreate, iLlamaContextCreate, 1];

iLlamaContextCreate[model_LlamaModel, opts_] :=
	Module[{params, ptr},
		params = contextDefaultParamsC[];
		ptr = newContextWithModelC[model["RawModel"], params];
		If[NullRawPointerQ[ptr],
			$Failed,
			LlamaContext[CreateManagedObject[ptr, freeC], params, model]
		]
	]


End[];
EndPackage[];