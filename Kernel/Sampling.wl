BeginPackage["ChristopherWolfram`LlamaLink`Sampling`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* LlamaDecode *)

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


End[];
EndPackage[];