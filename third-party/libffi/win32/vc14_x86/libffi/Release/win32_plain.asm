































 




























































































































































































































































































































































































































































































































































































































































































































































































































































































.386
.MODEL FLAT, C

EXTRN ffi_closure_SYSV_inner:NEAR
EXTRN ffi_closure_WIN32_inner:NEAR

_TEXT SEGMENT

ffi_call_win32 PROC NEAR,
    ffi_prep_args : NEAR PTR DWORD,
    ecif          : NEAR PTR DWORD,
    cif_abi       : DWORD,
    cif_bytes     : DWORD,
    cif_flags     : DWORD,
    rvalue        : NEAR PTR DWORD,
    fn            : NEAR PTR DWORD

        ;; Make room for all of the new args.
        mov  ecx, cif_bytes
        sub  esp, ecx

        mov  eax, esp

        ;; Call ffi_prep_args
        push ecif
        push eax
        call ffi_prep_args
        add  esp, 8

        ;; Prepare registers
        ;; EAX stores the number of register arguments
        cmp  eax, 0
        je   fun
        cmp  eax, 3
        jl   prepr_two_cmp
        
        mov  ecx, esp
        add  esp, 12
        mov  eax, DWORD PTR [ecx+8]
        jmp  prepr_two
prepr_two_cmp:
        cmp  eax, 2
        jl   prepr_one_prep
        mov  ecx, esp
        add  esp, 8
prepr_two:
        mov  edx, DWORD PTR [ecx+4]
        jmp  prepr_one
prepr_one_prep:
        mov  ecx, esp
        add  esp, 4
prepr_one:
        mov  ecx, DWORD PTR [ecx]
        cmp  cif_abi, 7 ;; FFI_REGISTER
        jne  fun

        xchg ecx, eax

fun:
        ;; Call function
        call fn

        ;; Load ecx with the return type code
        mov  ecx, cif_flags

        ;; If the return value pointer is NULL, assume no return value.
        cmp  rvalue, 0
        jne  ca_jumptable

        ;; Even if there is no space for the return value, we are
        ;; obliged to handle floating-point values.
        cmp  ecx, 2
        jne  ca_epilogue
        fstp st(0)

        jmp  ca_epilogue

ca_jumptable:
        jmp  [ca_jumpdata + 4 * ecx]
ca_jumpdata:
        ;; Do not insert anything here between label and jump table.
        dd offset ca_epilogue       ;; 0
        dd offset ca_retint         ;; 1
        dd offset ca_retfloat       ;; 2
        dd offset ca_retdouble      ;; 3
        dd offset ca_retlongdouble  ;; 3
        dd offset ca_retuint8       ;; 5
        dd offset ca_retsint8       ;; 6
        dd offset ca_retuint16      ;; 7
        dd offset ca_retsint16      ;; 8
        dd offset ca_retint         ;; 9
        dd offset ca_retint         ;; 10
        dd offset ca_retint64       ;; 11
        dd offset ca_retint64       ;; 12
        dd offset ca_epilogue       ;; 13
        dd offset ca_retint         ;; 14
        dd offset ca_retstruct1b    ;; (15 + 1)
        dd offset ca_retstruct2b    ;; (15 + 2)
        dd offset ca_retint         ;; (15 + 3)
        dd offset ca_epilogue       ;; (15 + 4)

        
ca_retuint8:
        movzx eax, al
        jmp   ca_retint

ca_retsint8:
        movsx eax, al
        jmp   ca_retint

ca_retuint16:
        movzx eax, ax
        jmp   ca_retint

ca_retsint16:
        movsx eax, ax
        jmp   ca_retint

ca_retint:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], eax
        jmp   ca_epilogue

ca_retint64:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], eax
        mov   [ecx + 4], edx
        jmp   ca_epilogue

ca_retfloat:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        fstp  DWORD PTR [ecx]
        jmp   ca_epilogue

ca_retdouble:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        fstp  QWORD PTR [ecx]
        jmp   ca_epilogue

ca_retlongdouble:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        fstp  TBYTE PTR [ecx]
        jmp   ca_epilogue

ca_retstruct1b:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], al
        jmp   ca_epilogue

ca_retstruct2b:
        ;; Load %ecx with the pointer to storage for the return value
        mov   ecx, rvalue
        mov   [ecx + 0], ax
        jmp   ca_epilogue

ca_epilogue:
        ;; Epilogue code is autogenerated.
        ret
ffi_call_win32 ENDP

ffi_closure_THISCALL PROC NEAR
        ;; Insert the register argument on the stack as the first argument
        xchg	DWORD PTR [esp+4], ecx
        xchg	DWORD PTR [esp], ecx
        push	ecx
        jmp	ffi_closure_STDCALL
ffi_closure_THISCALL ENDP

ffi_closure_FASTCALL PROC NEAR
        ;; Insert the 2 register arguments on the stack as the first argument
        xchg	DWORD PTR [esp+4], edx
        xchg	DWORD PTR [esp], ecx
        push	edx
        push	ecx
        jmp	ffi_closure_STDCALL
ffi_closure_FASTCALL ENDP

ffi_closure_REGISTER PROC NEAR
        ;; Insert the 3 register arguments on the stack as the first argument
        push	eax
        xchg	DWORD PTR [esp+8], ecx
        xchg	DWORD PTR [esp+4], edx
        push	ecx
        push	edx
        jmp	ffi_closure_STDCALL
ffi_closure_REGISTER ENDP

ffi_closure_SYSV PROC NEAR FORCEFRAME
    ;; the ffi_closure ctx is passed in eax by the trampoline.

        sub  esp, 40
        lea  edx, [ebp - 24]
        mov  [ebp - 12], edx         ;; resp
        lea  edx, [ebp + 8]
stub::
        mov  [esp + 8], edx          ;; args
        lea  edx, [ebp - 12]
        mov  [esp + 4], edx          ;; &resp
        mov  [esp], eax              ;; closure
        call ffi_closure_SYSV_inner
        mov  ecx, [ebp - 12]

cs_jumptable:
        jmp  [cs_jumpdata + 4 * eax]
cs_jumpdata:
        ;; Do not insert anything here between the label and jump table.
        dd offset cs_epilogue       ;; 0
        dd offset cs_retint         ;; 1
        dd offset cs_retfloat       ;; 2
        dd offset cs_retdouble      ;; 3
        dd offset cs_retlongdouble  ;; 3
        dd offset cs_retuint8       ;; 5
        dd offset cs_retsint8       ;; 6
        dd offset cs_retuint16      ;; 7
        dd offset cs_retsint16      ;; 8
        dd offset cs_retint         ;; 9
        dd offset cs_retint         ;; 10
        dd offset cs_retint64       ;; 11
        dd offset cs_retint64       ;; 12
        dd offset cs_retstruct      ;; 13
        dd offset cs_retint         ;; 14
        dd offset cs_retsint8       ;; (15 + 1)
        dd offset cs_retsint16      ;; (15 + 2)
        dd offset cs_retint         ;; (15 + 3)
        dd offset cs_retmsstruct    ;; (15 + 4)

cs_retuint8:
        movzx eax, BYTE PTR [ecx]
        jmp   cs_epilogue

cs_retsint8:
        movsx eax, BYTE PTR [ecx]
        jmp   cs_epilogue

cs_retuint16:
        movzx eax, WORD PTR [ecx]
        jmp   cs_epilogue

cs_retsint16:
        movsx eax, WORD PTR [ecx]
        jmp   cs_epilogue

cs_retint:
        mov   eax, [ecx]
        jmp   cs_epilogue

cs_retint64:
        mov   eax, [ecx + 0]
        mov   edx, [ecx + 4]
        jmp   cs_epilogue

cs_retfloat:
        fld   DWORD PTR [ecx]
        jmp   cs_epilogue

cs_retdouble:
        fld   QWORD PTR [ecx]
        jmp   cs_epilogue

cs_retlongdouble:
        fld   TBYTE PTR [ecx]
        jmp   cs_epilogue

cs_retstruct:
        ;; Caller expects us to pop struct return value pointer hidden arg.
        ;; Epilogue code is autogenerated.
        ret	4

cs_retmsstruct:
        ;; Caller expects us to return a pointer to the real return value.
        mov   eax, ecx
        ;; Caller doesn't expects us to pop struct return value pointer hidden arg.
        jmp   cs_epilogue

cs_epilogue:
        ;; Epilogue code is autogenerated.
        ret
ffi_closure_SYSV ENDP







ffi_closure_raw_THISCALL PROC NEAR USES esi FORCEFRAME
        sub esp, 36
        mov  esi, [eax + ((52 + 3) AND NOT 3)]        ;; closure->cif
        mov  edx, [eax + ((((52 + 3) AND NOT 3) + 4) + 4)]  ;; closure->user_data
        mov [esp + 12], edx
        lea edx, [ebp + 12]
        jmp stubraw
ffi_closure_raw_THISCALL ENDP

ffi_closure_raw_SYSV PROC NEAR USES esi FORCEFRAME
    ;; the ffi_closure ctx is passed in eax by the trampoline.

        sub  esp, 40
        mov  esi, [eax + ((52 + 3) AND NOT 3)]        ;; closure->cif
        mov  edx, [eax + ((((52 + 3) AND NOT 3) + 4) + 4)]  ;; closure->user_data
        mov  [esp + 12], edx                            ;; user_data
        lea  edx, [ebp + 8]
stubraw::
        mov  [esp + 8], edx                             ;; raw_args
        lea  edx, [ebp - 24]
        mov  [esp + 4], edx                             ;; &res
        mov  [esp], esi                                 ;; cif
        call DWORD PTR [eax + (((52 + 3) AND NOT 3) + 4)]   ;; closure->fun
        mov  eax, [esi + 20]              ;; cif->flags
        lea  ecx, [ebp - 24]

cr_jumptable:
        jmp  [cr_jumpdata + 4 * eax]
cr_jumpdata:
        ;; Do not insert anything here between the label and jump table.
        dd offset cr_epilogue       ;; 0
        dd offset cr_retint         ;; 1
        dd offset cr_retfloat       ;; 2
        dd offset cr_retdouble      ;; 3
        dd offset cr_retlongdouble  ;; 3
        dd offset cr_retuint8       ;; 5
        dd offset cr_retsint8       ;; 6
        dd offset cr_retuint16      ;; 7
        dd offset cr_retsint16      ;; 8
        dd offset cr_retint         ;; 9
        dd offset cr_retint         ;; 10
        dd offset cr_retint64       ;; 11
        dd offset cr_retint64       ;; 12
        dd offset cr_epilogue       ;; 13
        dd offset cr_retint         ;; 14
        dd offset cr_retsint8       ;; (15 + 1)
        dd offset cr_retsint16      ;; (15 + 2)
        dd offset cr_retint         ;; (15 + 3)
        dd offset cr_epilogue       ;; (15 + 4)

cr_retuint8:
        movzx eax, BYTE PTR [ecx]
        jmp   cr_epilogue

cr_retsint8:
        movsx eax, BYTE PTR [ecx]
        jmp   cr_epilogue

cr_retuint16:
        movzx eax, WORD PTR [ecx]
        jmp   cr_epilogue

cr_retsint16:
        movsx eax, WORD PTR [ecx]
        jmp   cr_epilogue

cr_retint:
        mov   eax, [ecx]
        jmp   cr_epilogue

cr_retint64:
        mov   eax, [ecx + 0]
        mov   edx, [ecx + 4]
        jmp   cr_epilogue

cr_retfloat:
        fld   DWORD PTR [ecx]
        jmp   cr_epilogue

cr_retdouble:
        fld   QWORD PTR [ecx]
        jmp   cr_epilogue

cr_retlongdouble:
        fld   TBYTE PTR [ecx]
        jmp   cr_epilogue

cr_epilogue:
        ;; Epilogue code is autogenerated.
        ret
ffi_closure_raw_SYSV ENDP



ffi_closure_STDCALL PROC NEAR FORCEFRAME
        mov  eax, [esp] ;; the ffi_closure ctx passed by the trampoline.

        sub  esp, 40
        lea  edx, [ebp - 24]
        mov  [ebp - 12], edx         ;; resp
        lea  edx, [ebp + 12]         ;; account for stub return address on stack
        mov  [esp + 8], edx          ;; args
        lea  edx, [ebp - 12]
        mov  [esp + 4], edx          ;; &resp
        mov  [esp], eax              ;; closure
        call ffi_closure_WIN32_inner
        mov  ecx, [ebp - 12]

        xchg [ebp + 4], eax          ;;xchg size of stack parameters and ffi_closure ctx
        mov  eax, DWORD PTR [eax + ((52 + 3) AND NOT 3)]
        mov  eax, DWORD PTR [eax + 20]

cd_jumptable:
        jmp  [cd_jumpdata + 4 * eax]
cd_jumpdata:
        ;; Do not insert anything here between the label and jump table.
        dd offset cd_epilogue       ;; 0
        dd offset cd_retint         ;; 1
        dd offset cd_retfloat       ;; 2
        dd offset cd_retdouble      ;; 3
        dd offset cd_retlongdouble  ;; 3
        dd offset cd_retuint8       ;; 5
        dd offset cd_retsint8       ;; 6
        dd offset cd_retuint16      ;; 7
        dd offset cd_retsint16      ;; 8
        dd offset cd_retint         ;; 9
        dd offset cd_retint         ;; 10
        dd offset cd_retint64       ;; 11
        dd offset cd_retint64       ;; 12
        dd offset cd_epilogue       ;; 13
        dd offset cd_retint         ;; 14
        dd offset cd_retsint8       ;; (15 + 1)
        dd offset cd_retsint16      ;; (15 + 2)
        dd offset cd_retint         ;; (15 + 3)

cd_retuint8:
        movzx eax, BYTE PTR [ecx]
        jmp   cd_epilogue

cd_retsint8:
        movsx eax, BYTE PTR [ecx]
        jmp   cd_epilogue

cd_retuint16:
        movzx eax, WORD PTR [ecx]
        jmp   cd_epilogue

cd_retsint16:
        movsx eax, WORD PTR [ecx]
        jmp   cd_epilogue

cd_retint:
        mov   eax, [ecx]
        jmp   cd_epilogue

cd_retint64:
        mov   eax, [ecx + 0]
        mov   edx, [ecx + 4]
        jmp   cd_epilogue

cd_retfloat:
        fld   DWORD PTR [ecx]
        jmp   cd_epilogue

cd_retdouble:
        fld   QWORD PTR [ecx]
        jmp   cd_epilogue

cd_retlongdouble:
        fld   TBYTE PTR [ecx]
        jmp   cd_epilogue

cd_epilogue:
        mov   esp, ebp
        pop   ebp
        mov   ecx, [esp + 4]  ;; Return address
        add   esp, [esp]      ;; Parameters stack size
        add   esp, 8
        jmp   ecx
ffi_closure_STDCALL ENDP

_TEXT ENDS
END


































































































































































































































































































































































































































































































































































































































































































































































































































































