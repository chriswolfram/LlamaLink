BeginPackage["ChristopherWolfram`LlamaLink`Batches`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Batch objects *)

DeclareObject[LlamaBatch, {_DataStructure, _ManagedObject	}];


(* Accessors *)

batch_LlamaBatch["RawBatchValue"] := batch[[1]]
batch_LlamaBatch["RawManagedObject"] := batch[[2]]

batch_LlamaBatch["RawBatch"] := batch["RawBatchValue"]["Get"]

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

batch_LlamaBatch["SetRawNTokens", v_] := batch["RawBatchValue"]["Set", ReplacePart[batch["RawBatch"], 1->v]]


(* Creating batches *)

batchInitC := batchInitC =
	ForeignFunctionLoad[$LibLlama, "llama_batch_init", {"Integer32", "Integer32", "Integer32"} -> Values@$BatchStruct];

batchFreeC := batchFreeC = 
	ForeignFunctionLoad[$LibLlama,  "llama_batch_free", {Values@$BatchStruct} -> "Void"];


DeclareFunction[LlamaBatchCreate, iLlamaBatchCreate, {1,3}];

iLlamaBatchCreate[ntokens_Integer, opts_] :=
	With[{batch = batchInitC[ntokens, 0, 1]},
		LlamaBatch[CreateDataStructure["Value", batch], CreateManagedObject[batch, batchFreeC]]
	]

iLlamaBatchCreate[tokens:{___Integer}, nPrev_Integer, includeLogits_?BooleanQ, opts_]  :=
	iLlamaBatchFill[iLlamaBatchCreate[Length[tokens], opts], tokens, nPrev, includeLogits, opts]

(* TODO: Do something ebtter here *)
iLlamaBatchCreate[arg1_, arg2_, opts_] :=
	$Failed


(* LlamaBatchFill *)

DeclareFunction[LlamaBatchFill, iLlamaBatchFill, 4];

iLlamaBatchFill[batch_LlamaBatch, tokens:{___Integer}, nPrev_Integer, includeLogits_?BooleanQ, opts_] :=
	(
		MapIndexed[
			({t, i} |-> (
				RawMemoryWrite[batch["RawTokens"], t, i];
				RawMemoryWrite[batch["RawPositions"], nPrev + i, i];
				RawMemoryWrite[batch["RawNSequenceIDs"], 1, i];
				RawMemoryWrite[RawMemoryRead[batch["RawSequenceIDs"], i], 0, 0];
				RawMemoryWrite[batch["RawLogits"], Boole[includeLogits], i];
			))[#1, First[#2]-1]&,
			tokens
		];
		RawMemoryWrite[batch["RawLogits"], 1, Length[tokens]-1];
		
		batch["SetRawNTokens", Length[tokens]];
		batch
	)


End[];
EndPackage[];