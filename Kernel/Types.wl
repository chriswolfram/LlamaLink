BeginPackage["ChristopherWolfram`LlamaLink`Types`"];

$BoolType
$TokenType
$PosType
$SeqIDType

$ModelParamsStruct
$ContextParamsStruct
$BatchStruct
$TokenDataStruct
$TokenDataArrayStruct

Begin["`Private`"];

Needs["ChristopherWolfram`LlamaLink`"]


(* Basic *)

$BoolType = "CChar";
$TokenType = "Integer32";
$PosType = "Integer32";
$SeqIDType = "Integer32";


(* Structs *)

$ModelParamsStruct = {
	"n_gpu_layers"                -> "Integer32",
	"split_mode"                  -> "UnsignedInteger32",
	"main_gpu"                    -> "Integer32",
	"tensor_split"                -> "RawPointer"::["CFloat"],
	"progress_callback"           -> "OpaqueRawPointer",
	"progress_callback_user_data" -> "OpaqueRawPointer",
	"kv_overrides"                -> "OpaqueRawPointer",
	"vocab_only"                  -> $BoolType,
	"use_mmap"                    -> $BoolType,
	"use_mlock"                   -> $BoolType
};


$ContextParamsStruct = {
	"seed"              -> "UnsignedInteger32",
	"n_ctx"             -> "UnsignedInteger32",
	"n_batch"           -> "UnsignedInteger32",
	"n_threads"         -> "UnsignedInteger32",
	"n_threads_batch"   -> "UnsignedInteger32",
	"rope_scaling_type" -> "Integer8",
	"rope_freq_base"    -> "CFloat",
	"rope_freq_scale"   -> "CFloat",
	"yarn_ext_factor"   -> "CFloat",
	"yarn_attn_factor"  -> "CFloat",
	"yarn_beta_fast"    -> "CFloat",
	"yarn_beta_slow"    -> "CFloat",
	"yarn_orig_ctx"     -> "UnsignedInteger32",
	"cb_eval"           -> "OpaqueRawPointer",
	"cb_eval_user_data" -> "OpaqueRawPointer",
	"type_k"            -> "UnsignedInteger32",
	"type_v"            -> "UnsignedInteger32",
	"mul_mat_q"         -> $BoolType,
	"logits_all"        -> $BoolType,
	"embedding"         -> $BoolType,
	"offload_kqv"       -> $BoolType
};

$BatchStruct = {
	"n_tokens"   -> "Integer32",
	"token"      -> "RawPointer"::[$TokenType],
	"embd"       -> "RawPointer"::["CFloat"],
	"pos"        -> "RawPointer"::[$PosType],
	"n_seq_id"   -> "RawPointer"::["Integer32"],
	"seq_id"     -> "RawPointer"::["RawPointer"::[$SeqIDType]],
	"logits"     -> "RawPointer"::["Integer8"],

	(*below are going to be depricated in the future*)
	"all_pos_0"  -> $PosType,
	"all_pos_1"  -> $PosType,
	"all_seq_id" -> $SeqIDType
};


$TokenDataStruct = {
	"id"    -> $TokenType,
	"logit" -> "CFloat",
	"p"     -> "CFloat"
};


$TokenDataArrayStruct = {
	"data"   -> "RawPointer"::[Values@$TokenDataStruct],
	"size"   -> "CSizeT",
	"sorted" -> $BoolType
}


End[];
EndPackage[];