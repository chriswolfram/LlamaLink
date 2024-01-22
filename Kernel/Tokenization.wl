BeginPackage["ChristopherWolfram`LlamaLink`Tokenization`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Tokenize *)

tokenizeC := tokenizeC =
	ForeignFunctionLoad[$LibLlama, "llama_tokenize", {
			"OpaqueRawPointer",
			"RawPointer"::["CUnsignedChar"],
			"Integer32",
			"RawPointer"::[$TokenType],
			"Integer32",
			$BoolType,
			$BoolType
		} -> "Integer32"
	];


Options[LlamaTokenize] = {
	"IncludeStartOfStringToken" -> True,
	"SpecialTokens" -> False
};

DeclareFunction[LlamaTokenize, iLlamaTokenize, 2];

(* Based on the std::vector<llama_token> llama_tokenize function in common.cpp *)
iLlamaTokenize[model_LlamaModel, inputBytes_ByteArray, opts_] :=
	Enclose@Module[{addBOS, special, inputBuf, bufsize, buf, ntokens, ntokens2},

		addBOS = ConfirmBy[OptionValue[LlamaTokenize, opts, "IncludeStartOfStringToken"], BooleanQ];
		special = ConfirmBy[OptionValue[LlamaTokenize, opts, "SpecialTokens"], BooleanQ];

		inputBuf = RawMemoryExport[inputBytes, "CUnsignedChar"];
		bufsize = Length[inputBytes] + Boole[addBOS];
		buf = RawMemoryAllocate[$TokenType, bufsize];

		ntokens = tokenizeC[model["RawModel"], inputBuf, Length[inputBytes], buf, bufsize, Boole[addBOS], Boole[special]];

		If[Negative[ntokens],
				bufsize = -ntokens;
				buf = RawMemoryAllocate[$TokenType, bufsize];
				ntokens2 = tokenizeC[model["RawModel"], inputBuf, Length[inputBytes], buf, bufsize, Boole[addBOS], Boole[special]];
				ConfirmAssert[ntokens2 =!= -ntokens];
				ntokens = ntokens2;
			];

		RawMemoryImport[buf, {"List", ntokens}]
	]

iLlamaTokenize[model_LlamaModel, inputString_?StringQ, opts_] :=
	iLlamaTokenize[model, StringToByteArray[inputString, "UTF8"], opts]


(* Detokenize *)

tokenToPieceC := tokenToPieceC =
	ForeignFunctionLoad[$LibLlama, "llama_token_to_piece", {
		"OpaqueRawPointer",
		"Integer32",
		"RawPointer"::["CUnsignedChar"],
		"Integer32"
		} -> "Integer32"
	];

DeclareFunction[LlamaDetokenize, iLlamaDetokenize, 2];

(* Based on the std::string llama_token_to_piece function in common.cpp *)
iLlamaDetokenize[model_LlamaModel, token_Integer, opts_] :=
	Enclose@Module[{bufsize, buf, nchars, nchars2},

		bufsize = 8;
		buf = RawMemoryAllocate["CUnsignedChar", bufsize];

		nchars = tokenToPieceC[model["RawModel"], token, buf, bufsize];

		If[Negative[nchars],
			bufsize = -nchars;
			buf = RawMemoryAllocate["CUnsignedChar", bufsize];
			nchars2 = tokenToPieceC[model["RawModel"], token, buf, bufsize];
			ConfirmAssert[nchars2 =!= -nchars];
			nchars = nchars2
		];

		RawMemoryImport[buf, {"String", nchars}]
	]

iLlamaDetokenize[model_LlamaModel, tokens:{___Integer}, opts_] :=
	StringJoin[iLlamaDetokenize[model, #, opts] &/@ tokens]


End[];
EndPackage[];