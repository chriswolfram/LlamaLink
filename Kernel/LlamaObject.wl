BeginPackage["ChristopherWolfram`LlamaLink`LlamaObject`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Objects *)

DeclareObject[LlamaObject, {
	_LlamaContext,
	_LlamaBatch,
	_DataStructure,
	_DataStructure
}];


(* Accessors *)

llama_LlamaObject["Context"] := llama[[1]]
llama_LlamaObject["Batch"] := llama[[2]]
llama_LlamaObject["RawNTokens"] := llama[[3]]
llama_LlamaObject["RawLogits"] := llama[[4]]

llama_LlamaObject["Model"] := llama["Context"]["Model"]
llama_LlamaObject["Logits"] := llama["RawLogits"]["Get"]


(* Constructors *)

DeclareFunction[LlamaObjectCreate, iLlamaObjectCreate, 1]

iLlamaObjectCreate[ctx_LlamaContext, batch_LlamaBatch, opts_] :=
	LlamaObject[ctx, batch, CreateDataStructure["Counter",0], CreateDataStructure["Value",Missing[]]]

(* TODO: Unclear what n_batch actually is, and whether this is what it is for *)
iLlamaObjectCreate[ctx_LlamaContext, opts_] :=
	iLlamaObjectCreate[ctx, LlamaBatchCreate[ctx["RawNBatch"]], opts]

iLlamaObjectCreate[model_LlamaModel, opts_] :=
	iLlamaObjectCreate[LlamaContextCreate[model], opts]

iLlamaObjectCreate[path:(_?StringQ | File[_?StringQ]), opts_] :=
	iLlamaObjectCreate[LlamaModelCreate[path], opts]


(* Utilities *)

llamaReset[llama_] :=
	llama["RawNTokens"]["Set", 0]


(* Evaluation *)

DeclareFunction[LlamaEvaluate, iLlamaEvaluate, 2];

iLlamaEvaluate[llama_LlamaObject, tokens:{___Integer}, opts_] :=
	Module[{ctx, batch, logitsAll, nPrev, logits},

		ctx = llama["Context"];
		batch = llama["Batch"];

		(* ctx["KVCacheSequenceRemove", -1, llama["RawNTokens"]["Get"], -1]; *)

		logitsAll = ctx["LogitsAll"] > 0;

		BlockMap[
			batchTokens |-> (

				nPrev = llama["RawNTokens"]["Get"];

				LlamaBatchFill[batch, tokens, nPrev, logitsAll];
				LlamaDecode[ctx, batch];

				llama["RawNTokens"]["AddTo", Length[tokens]]

			),
			tokens,
			UpTo[ctx["RawNBatch"]]
		];

		logits = llama["Context"]["RawGetLogits", Length[tokens]-1];
		llama["RawLogits"]["Set", logits];

	]

iLlamaEvaluate[llama_LlamaObject, tokens_, opts_] :=
	Enclose@iLlamaEvaluate[llama, Confirm@LlamaTokenize[llama, tokens], opts]


(* Sampling *)

DeclareFunction[LlamaSample, iLlamaSample, 1];

Options[LlamaSample] = {
	"Temperature" -> 0.7
};

iLlamaSample[llama_LlamaObject, opts_] :=
	Enclose@Module[{logits, candidates, temp},
		ConfirmAssert[llama["RawNTokens"]["Get"] > 0, "Cannot sample when there has been no evaluation."];

		logits = llama["Logits"];

		candidates = LlamaCandidatesCreate[logits];

		temp = OptionValue[LlamaSample, opts, "Temperature"];
		If[TrueQ[temp > 0],
			LlamaCandidatesPrepare[llama["Context"], candidates, {"Temperature", temp}];
			LlamaCandidatesSample[llama["Context"], candidates, "Probabilistic"]
			,
			LlamaCandidatesSample[llama["Context"], candidates, "Greedy"]
		]

	]


(* Generation *)

DeclareFunction[LlamaGenerate, iLlamaGenerate, 2];

Options[LlamaGenerate] = Join[
	Options[LlamaSample],
	{
		"MaxTokens" -> Automatic,
		"StopTokens" -> Automatic,
		HandlerFunctions -> <||>
	}
];

iLlamaGenerate[llama_LlamaObject, promptTokens:{___Integer}, opts_] :=
	Enclose@Module[{maxTokens, stopTokens, callback, tokens, newToken},

		llamaReset[llama];

		maxTokens = ConfirmMatch[Replace[OptionValue[LlamaGenerate, opts, "MaxTokens"], Automatic->Infinity], _Integer | Infinity];

		stopTokens = ConfirmMatch[Replace[OptionValue[LlamaGenerate, opts, "StopTokens"], Automatic->{}], {_?StringQ...}];
		stopTokens = Append[stopTokens, llama["Model"]["EndOfStringToken"]];

		callback = Lookup[OptionValue[LlamaGenerate, opts, HandlerFunctions], "NewToken", Identity];

		(* Evaluate the prompt *)
		LlamaEvaluate[llama, promptTokens];

		(* Start generating tokens until we hit the stop *)
		tokens = {};
		Do[
			newToken = LlamaSample[llama, FilterRules[opts, Options[LlamaSample]]];
			If[MemberQ[stopTokens, newToken], Break[]];
			callback[newToken];
			AppendTo[tokens, newToken];
			LlamaEvaluate[llama, {newToken}]
			,
			maxTokens
		];

		tokens
	]

iLlamaGenerate[llama_LlamaObject, promptStr_?StringQ, opts_] :=
	Enclose@LlamaDetokenize[llama, Confirm@iLlamaGenerate[llama, Confirm@LlamaTokenize[llama, promptStr], opts]]


End[];
EndPackage[];