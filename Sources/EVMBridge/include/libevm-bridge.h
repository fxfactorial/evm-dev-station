/* Code generated by cmd/cgo; DO NOT EDIT. */

/* package command-line-arguments */


#line 1 "cgo-builtin-export-prolog"

#include <stddef.h>

#ifndef GO_CGO_EXPORT_PROLOGUE_H
#define GO_CGO_EXPORT_PROLOGUE_H

#ifndef GO_CGO_GOSTRING_TYPEDEF
typedef struct { const char *p; ptrdiff_t n; } _GoString_;
#endif

#endif

/* Start of preamble from import "C" comments.  */


#line 3 "main.go"

#include <stdbool.h>
extern void evm_run_callback(int, char*, char*, int);
extern void chain_load_finished();
// callee, caller, args
extern void evm_opcall_callback(char*, char*, char*);
extern void evm_opcode_callback(char*, char**, int, char*);

struct NewContractResult {
   bool is_error;
   char* error_reason;
   size_t error_reason_size;
   char* new_contract_addr;
};

struct CallContractResult {
   char* error_reason;
   size_t error_reason_size;
   char* call_return_value;
   size_t call_return_size;
};

struct SetAccountBalanceResult {
   char *error_reason;
   size_t error_reason_size;
};

struct LoadChainDataResult {
  char *error_reason;
  size_t error_reason_size;
};

struct ChainHeadResult {
  char *error_reason;
  size_t error_reason_size;
  char *chain_head_json;
  size_t chain_head_json_size;
};

extern void send_cmd_back(char*);


#line 1 "cgo-generated-wrapper"


/* End of preamble from import "C" comments.  */


/* Start of boilerplate cgo prologue.  */
#line 1 "cgo-gcc-export-header-prolog"

#ifndef GO_CGO_PROLOGUE_H
#define GO_CGO_PROLOGUE_H

typedef signed char GoInt8;
typedef unsigned char GoUint8;
typedef short GoInt16;
typedef unsigned short GoUint16;
typedef int GoInt32;
typedef unsigned int GoUint32;
typedef long long GoInt64;
typedef unsigned long long GoUint64;
typedef GoInt64 GoInt;
typedef GoUint64 GoUint;
typedef size_t GoUintptr;
typedef float GoFloat32;
typedef double GoFloat64;
#ifdef _MSC_VER
#include <complex.h>
typedef _Fcomplex GoComplex64;
typedef _Dcomplex GoComplex128;
#else
typedef float _Complex GoComplex64;
typedef double _Complex GoComplex128;
#endif

/*
  static assertion to make sure the file is being used on architecture
  at least with matching size of GoInt.
*/
typedef char _check_for_64_bit_pointer_matching_GoInt[sizeof(void*)==64/8 ? 1:-1];

#ifndef GO_CGO_GOSTRING_TYPEDEF
typedef _GoString_ GoString;
#endif
typedef void *GoMap;
typedef void *GoChan;
typedef struct { void *t; void *v; } GoInterface;
typedef struct { void *data; GoInt len; GoInt cap; } GoSlice;

#endif

/* End of boilerplate cgo prologue.  */

#ifdef __cplusplus
extern "C" {
#endif

extern void MakeChannelAndListenThread(GoUint8 enableLogging);
extern void MakeChannelAndReplyThread(GoUint8 enableLogging);
extern void UISendCmd(GoString msg);
extern char* Keccak256(GoString payload);
extern void DoHookOnOpcode(GoUint8 doHook, GoString opcodeName);
extern void EnableHookEveryOpcode(GoUint8 status);
extern void ResetEVM(GoUint8 enableOpCodeCallback, GoUint8 enableCallback, GoUint8 useStateInMemory);
extern void EnableOPCodeCallHook(GoUint8 status);
extern void SendValueToPausedEVMInOpCode(GoUint8 useOverrides, GoString serializedStack, GoString memory);
extern void SendValueToPausedEVMInCall(GoUint8 useOverrides, GoString caller_, GoString callee_, GoString payload_);

/* Return type for AllKnownOpcodes */
struct AllKnownOpcodes_return {
	char** r0;
	int r1;
};
extern struct AllKnownOpcodes_return AllKnownOpcodes();
extern int TestReceiveGoString(GoString input_);
extern void NewGlobalEVM();
extern void PauseOnOpcode(char code);
extern void UseLoadedStateOnEVM();
extern void EnableCallback(GoUint8 status);
extern void EnableStopOnCall(GoUint8 enable);
extern struct SetAccountBalanceResult SetAccountBalance(GoString account, GoString balance);
extern void TestSendingInt(GoString msgValue_);
extern struct CallContractResult CallEVM(GoString calldataSwift_, GoString targetAddrSwift_, GoString msgValueSwift_);
extern struct NewContractResult DeployNewContract(GoString bytecode_, GoString caller_);
extern int RunCodeOnContract(int sessionID, char* calldata, int calldataLength, char* callerAddr);
extern void CallGoFromSwift();

/* Return type for AvailableEIPS */
struct AvailableEIPS_return {
	int* r0;
	GoInt r1;
};
extern struct AvailableEIPS_return AvailableEIPS();

#ifdef __cplusplus
}
#endif
