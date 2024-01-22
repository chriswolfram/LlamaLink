BeginPackage["ChristopherWolfram`LlamaLink`Sampling`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Decoding *)

DeclareFunction[LlamaDecode, iLlamaDecode, 2];

decodeC := decodeC = 
	ForeignFunctionLoad[$LibLlama, "llama_decode", {"OpaqueRawPointer", Values@$BatchStruct} -> "Integer32"];

iLlamaDecode[ctx_LlamaContext, batch_LlamaBatch, opts_] :=
	With[{res = decodeC[ctx["RawContext"], batch["RawBatch"]]},
		Switch[res,
			0, Success["DecodingCompleted", <|"Message" -> "Decoded successfully."|>],
			1, Failure["DecodingFailure", <|"Message" -> "Could not find a KV slot for the batch (try reducing the size of the batch or increase the context)."|>],
			_, Failure["DecodingFailure", <|"MessageTemplate" -> "Decoding failed with error code `1`", "MessageParameters" -> {res}, "ErrorCode" -> res|>]
		]
	]


(* Candidates *)

DeclareObject[LlamaCandidates, {_ManagedObject}];


(* Accessors *)

candidates_LlamaCandidates["RawCandidates"] := candidates[[1]]

candidates_LlamaCandidates["RawTokenData"] :=
	Module[{tokenDataArray},
		tokenDataArray = RawMemoryRead[candidates["RawCandidates"]];
		RawMemoryImport[tokenDataArray[[1]], {"List", tokenDataArray[[2]]}]
	]


(* Constructors *)

DeclareFunction[LlamaCandidatesCreate, iLlamaCandidatesCreate, 1];

iLlamaCandidatesCreate[logits:{___Real}, opts_] :=
	Module[{nvocab, tokenDatas, tokenDataArray},
		nvocab = Length[logits];
		tokenDatas = RawMemoryExport[{# - 1, logits[[#]], 0.0} & /@ Range[nvocab], Values@$TokenDataStruct];
		tokenDataArray = RawMemoryExport[{{tokenDatas, nvocab, 0}}, Values@$TokenDataArrayStruct];
		LlamaCandidates[tokenDataArray]
	]


(* LlamaCandidatesPrepare *)

DeclareFunction[LlamaCandidatesPrepare, iLlamaCandidatesPrepare, 3];

sampleSoftmaxC = 
	ForeignFunctionLoad[$LibLlama, "llama_sample_softmax", {"OpaqueRawPointer", "RawPointer"::[Values@$TokenDataArrayStruct]} -> "Void"];

sampleTempC = 
	ForeignFunctionLoad[$LibLlama, "llama_sample_temp", {"OpaqueRawPointer", "RawPointer"::[Values@$TokenDataArrayStruct], "CFloat"} -> "Void"];


iLlamaCandidatesPrepare[ctx_LlamaContext, candidates_LlamaCandidates, "Softmax", opts_] :=
	(
		sampleSoftmaxC[ctx["RawContext"], candidates["RawCandidates"]];
		candidates
	)

iLlamaCandidatesPrepare[ctx_LlamaContext, candidates_LlamaCandidates, {"Temperature", temp_Real}, opts_] :=
	(
		sampleTempC[ctx["RawContext"], candidates["RawCandidates"], temp];
		candidates
	)


(* LlamaCandidatesSample *)

DeclareFunction[LlamaCandidatesSample, iLlamaCandidatesSample, {2,3}];

sampleTokenC := sampleTokenC = 
	ForeignFunctionLoad[$LibLlama, "llama_sample_token", {"OpaqueRawPointer", "RawPointer"::[Values@$TokenDataArrayStruct]} -> $TokenType];

sampleTokenGreedyC := sampleTokenGreedyC = 
  ForeignFunctionLoad[$LibLlama, "llama_sample_token_greedy", {"OpaqueRawPointer", "RawPointer"::[Values@$TokenDataArrayStruct]} -> $TokenType];


iLlamaCandidatesSample[ctx_LlamaContext, candidates_LlamaCandidates, "Probabilistic", opts_] :=
	sampleTokenC[ctx["RawContext"], candidates["RawCandidates"]]

iLlamaCandidatesSample[ctx_LlamaContext, candidates_LlamaCandidates, "Greedy", opts_] :=
	sampleTokenGreedyC[ctx["RawContext"], candidates["RawCandidates"]]


iLlamaCandidatesSample[ctx_, candidates_, opts_] :=
	iLlamaCandidatesSample[ctx, candidates, "Probabilistic", opts]


End[];
EndPackage[];