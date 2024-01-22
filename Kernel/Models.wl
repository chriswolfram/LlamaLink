BeginPackage["ChristopherWolfram`LlamaLink`Models`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]
Needs["ChristopherWolfram`LlamaLink`Utilities`"]


(* Model objects *)

DeclareObject[LlamaModel, {_ManagedObject}];


(* Accessors *)

model_LlamaModel["RawModel"] := model[[1]]


nvocabC := nvocabC =
	ForeignFunctionLoad[$LibLlama, "llama_n_vocab", {"OpaqueRawPointer"} -> "Integer32"];

model_LlamaModel["VocabularySize"] := nvocabC[model["RawModel"]]


tokenEOSC := tokenEOSC =
	ForeignFunctionLoad[$LibLlama, "llama_token_eos", {"OpaqueRawPointer"} -> $TokenType];

model_LlamaModel["EndOfStringToken"] := tokenEOSC[model["RawModel"]]


(* Loading models *)

modelDefaultParamsC := modelDefaultParamsC =
	ForeignFunctionLoad[$LibLlama, "llama_model_default_params", {} -> Values@$ModelParamsStruct];

loadModelFromFileC := loadModelFromFileC = 
	ForeignFunctionLoad[$LibLlama,  "llama_load_model_from_file", {"RawPointer"::["CUnsignedChar"], Values@$ModelParamsStruct} -> "OpaqueRawPointer"];

freeModelC := freeModelC = 
	ForeignFunctionLoad[$LibLlama,  "llama_free_model", {"OpaqueRawPointer"} -> "Void"];


DeclareFunction[LlamaModelCreate, iLlamaModelCreate, 1];

iLlamaModelCreate[path_, opts_] :=
	Enclose@Module[{ptr},
		ptr = loadModelFromFileC[Confirm@AbsoluteFileName@path, modelDefaultParamsC[]];
		If[NullRawPointerQ[ptr],
			$Failed,
			LlamaModel[CreateManagedObject[ptr, freeModelC]]
		]
	]


End[];
EndPackage[];