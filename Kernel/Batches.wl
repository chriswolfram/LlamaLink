BeginPackage["ChristopherWolfram`LlamaLink`Batches`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Batch objects *)

DeclareObject[LlamaBatch, {
		{
			_Integer,
			HoldPattern[RawPointer][_Integer, "Integer32"],
			HoldPattern[RawPointer][_Integer, "CFloat"],
			HoldPattern[RawPointer][_Integer, "Integer32"],
			HoldPattern[RawPointer][_Integer, "Integer32"],
			HoldPattern[RawPointer][_Integer, TypeSpecifier["RawPointer"]["Integer32"]],
			HoldPattern[RawPointer][_Integer, "Integer8"],
			_Integer,
			_Integer,
			_Integer
		},
		_ManagedObject
	}
];


(* Accessors *)

batch_LlamaBatch["RawBatch"] := batch[[1]]

batch_LlamaBatch["RawNTokens"] := batch["RawBatch"][[1]]
batch_LlamaBatch["RawTokens"] := batch["RawBatch"][[2]]
batch_LlamaBatch["RawEmbeddings"] := batch["RawBatch"][[3]]
batch_LlamaBatch["RawPositions"] := batch["RawBatch"][[4]]
batch_LlamaBatch["RawNSequenceIDs"] := batch["RawBatch"][[5]]
batch_LlamaBatch["RawSequenceIDs"] := batch["RawBatch"][[6]]
batch_LlamaBatch["RawLogits"] := batch["RawBatch"][[7]]
batch_LlamaBatch["RawAllPositions0"] := batch["RawBatch"][[8]]
batch_LlamaBatch["RawAllPositions1"] := batch["RawBatch"][[9]]
batch_LlamaBatch["RawAllSequenceIDs"] := batch["RawBatch"][[10]]


(* Creating batches *)

batchInitC := batchInitC =
	ForeignFunctionLoad[$LibLlama, "llama_batch_init", {"Integer32", "Integer32", "Integer32"} -> Values@$BatchStruct];

batchFreeC := freeModelC = 
	ForeignFunctionLoad[$LibLlama,  "llama_batch_free", {Values@$BatchStruct} -> "Void"];


DeclareFunction[LlamaBatchCreate, iLlamaBatchCreate, 1];

iLlamaBatchCreate[ntokens_Integer, opts_] :=
	With[{batch = batchInitC[ntokens, 0, 1]},
		LlamaBatch[batch, CreateManagedObject[batch, batchFreeC]]
	]


End[];
EndPackage[];