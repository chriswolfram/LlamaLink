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


DeclareFunction[LlamaBatchCreate, iLlamaBatchCreate, {1,3}];

iLlamaBatchCreate[ntokens_Integer, opts_] :=
	With[{batch = batchInitC[ntokens, 0, 1]},
		LlamaBatch[batch, CreateManagedObject[batch, batchFreeC]]
	]

iLlamaBatchCreate[tokens:{___Integer}, pos:{___Integer}, includeLogits:{_?BooleanQ...}, opts_] /;
	Length[tokens] === Length[pos] === Length[includeLogits] :=
	iLlamaBatchFill[iLlamaBatchCreate[Length[tokens], opts], tokens, pos, includeLogits, opts]

(* TODO: Do something ebtter here *)
iLlamaBatchCreate[arg1_, arg2_, opts_] :=
	$Failed


(* LlamaBatchFill *)

DeclareFunction[LlamaBatchFill, iLlamaBatchFill, 4];

iLlamaBatchFill[batch_LlamaBatch, tokens:{___Integer}, pos:{___Integer}, includeLogits:{_?BooleanQ...}, opts_] /;
	Length[tokens] === Length[pos] === Length[includeLogits] :=
	(
		MapThread[
			{t, p, il, i} |-> (
				RawMemoryWrite[batch["RawTokens"], t, i];
				RawMemoryWrite[batch["RawPositions"], p, i];
				RawMemoryWrite[batch["RawNSequenceIDs"], 1, i];
				RawMemoryWrite[RawMemoryRead[batch["RawSequenceIDs"], i], 0, 0];
				RawMemoryWrite[batch["RawLogits"], Boole[il], i];
			),
			{
				tokens, pos, includeLogits, Range[0,Length[tokens]-1]
			}
		];
		
		LlamaBatch[
			{
				Length[tokens],
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
	)


End[];
EndPackage[];