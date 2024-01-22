BeginPackage["ChristopherWolfram`LlamaLink`LibLlama`"];

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]


$LlamaInstallPath := $LlamaInstallPath = "/Users/christopher/git/LlamaLink/llama.cpp/build/install";

$LibLlama := $LibLlama = FileNameJoin[{$LlamaInstallPath, "lib", "libllama.dylib"}];


End[];
EndPackage[];