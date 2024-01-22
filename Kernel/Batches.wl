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
batch_LlamaBatch["RawManagedObject"] := batch[[2]]

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

batchFreeC := batchFreeC = 
	ForeignFunctionLoad[$LibLlama,  "llama_batch_free", {Values@$BatchStruct} -> "Void"];


DeclareFunction[LlamaBatchCreate, iLlamaBatchCreate, 1];

iLlamaBatchCreate[ntokens_Integer, opts_] :=
	With[{batch = batchInitC[ntokens, 0, 1]},
		LlamaBatch[batch, CreateManagedObject[batch, batchFreeC]]
	]


(* LlamaBatchAppend *)

DeclareFunction[LlamaBatchAppend, iLlamaBatchAppend, {3,4}];

(* Based on llama_batch_add *)
iLlamaBatchAppend[batch_LlamaBatch, token_Integer, pos_Integer, includeLogits_?BooleanQ, opts_] :=
	Module[{},
		RawMemoryWrite[batch["RawTokens"], token, batch["RawNTokens"]];
		RawMemoryWrite[batch["RawPositions"], pos, batch["RawNTokens"]];
		RawMemoryWrite[batch["RawNSequenceIDs"], 1, batch["RawNTokens"]];
		RawMemoryWrite[RawMemoryRead[batch["RawSequenceIDs"], batch["RawNTokens"]], 0, 0];
		RawMemoryWrite[batch["RawLogits"], Boole[includeLogits], batch["RawNTokens"]];
		
		LlamaBatch[
			{
				batch["RawNTokens"] + 1,
				batch["RawTokens"],
				batch["RawEmbeddings"],
				batch["RawPositions"],
				batch["RawNSequenceIDs"],
				batch["RawSequenceIDs"],
				batch["RawLogits"],
				batch["RawAllPositions0"],
				batch["RawAllPositions1"],
				batch["RawAllSequenceIDs"]
			},
			batch["RawManagedObject"]
		]
	]

iLlamaBatchAppend[batch_LlamaBatch, token_Integer, pos_Integer, opts_] :=
	iLlamaBatchAppend[batch, token, pos, True, opts]


(* LlamaBatchClear *)

DeclareFunction[LlamaBatchClear, iLlamaBatchClear, 1];

(* Based on llama_batch_clear *)

iLlamaBatchClear[batch_LlamaBatch, opts_] :=
	LlamaBatch[
		{
			0,
			batch["RawTokens"],
			batch["RawEmbeddings"],
			batch["RawPositions"],
			batch["RawNSequenceIDs"],
			batch["RawSequenceIDs"],
			batch["RawLogits"],
			batch["RawAllPositions0"],
			batch["RawAllPositions1"],
			batch["RawAllSequenceIDs"]
		},
		batch["RawManagedObject"]
	]


End[];
EndPackage[];