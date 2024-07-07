BeginPackage["ChristopherWolfram`LlamaLink`Initialization`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]
Needs["ChristopherWolfram`LlamaLink`LibLlama`"]
Needs["ChristopherWolfram`LlamaLink`Types`"]


backedInitC := backedInitC =
	ForeignFunctionLoad[$LibLlama, "llama_backend_init", {} -> "Void"];


(* TODO: This should not have to be called by the user. *)
(* TODO: This thing with GGML_METAL_PATH_RESOURCES is a workaround. Unclear what the intended solution is. *)
InitializeLlama[] := (
	SetEnvironment["GGML_METAL_PATH_RESOURCES" -> FileNameJoin[{$LlamaInstallPath, "bin"}]];
	backedInitC[]
)


End[];
EndPackage[];