        .include "constants.s"

        .macro assert_equals expected actual
        .if (\expected != \actual)
        .error "Assertion failed: \expected \actual"
        .endif
        .endm

        .macro mov_reg from to
        .ifnb \from
        .ifnc \from, \to
        movq   \from, \to
        .endif
        .endif
        .endm

        .macro call_fn fn arg1 arg2 arg3 arg4 arg5 arg6
        mov_reg \arg6, %r9
        mov_reg \arg5, %r8
        mov_reg \arg4, %rcx
        mov_reg \arg3, %rdx
        mov_reg \arg2, %rsi
        mov_reg \arg1, %rdi
        call \fn
        .endm

        .macro local_variables local:req locals:vararg
        .equ \local, local_offset
        .equ local_offset, local_offset + POINTER_SIZE
        .ifnb \locals
        local_variables \locals
        .endif
        .endm

        .macro prologue locals:vararg
        .equ local_offset, 0
        .ifnb \locals
        local_variables \locals
        .endif
        .equ stack_frame_size, (8 + ((8 + local_offset) & -16))
        sub     $stack_frame_size, %rsp
        .endm

        .macro return value1=%rax value2=%rdx
        mov_reg \value1, %rax
        mov_reg \value2, %rdx
        add     $stack_frame_size, %rsp
        ret
        .endm

        .macro unbox_int_internal int to=%rax
        movsx   \int, \to
        .endm

        .macro unbox_pointer_internal ptr to=%rax
        mov     $PAYLOAD_MASK, \to
        and     \ptr, \to
        .endm

        .macro eq_internal x y tmp=%rax
        .ifnc \x, \tmp
        mov     \x, \tmp
        .endif
        cmp     \tmp, \y
        sete    %al
        and     $C_TRUE, %rax
        .endm

        .macro box_int_internal value tmp=%r11
        .ifnc \value, %eax
        mov     \value, %eax
        .endif
        mov     $(NAN_MASK | TAG_INT), \tmp
        or      \tmp, %rax
        .endm

        .macro box_boolean_internal value
        tag     TAG_BOOLEAN, %rax
        .endm

        .macro tag tag value tmp=%r11
        .ifnc \value, %rax
        mov     \value, %rax
        .endif
        mov     $(NAN_MASK | \tag), \tmp
        or      \tmp, %rax
        .endm

        .macro has_tag tag value tmp=%r11
        mov     $TAG_MASK, \tmp
        and     \value, \tmp
        eq_internal \tag, \tmp
        .endm

        .macro is_double_internal value tmp=%r11
        mov     $(SIGN_BIT - 1), \tmp
        and     \tmp, \value
        mov     $NAN_MASK, \tmp
        cmp     \tmp, \value
        setle   %al
        and     $C_TRUE, %rax
        .endm

        .macro tagged_jump table tmp=%rbx
        prologue
        mov     %rdi, %rax
        xor     \tmp, \tmp
        is_double_internal %rax
        cmovz   %rdi, \tmp
        mov     $TAG_MASK, %rax
        and     \tmp, %rax
        shr     $TAG_SHIFT, %rax
        call    *\table(,%rax,POINTER_SIZE)
        return
        .endm

        .macro arraycopy from to size
        mov     \from, %rsi
        mov     \to, %rdi
        mov     \size, %rcx

        lea     (%rsi, %rcx), %rsi
        lea     (%rdi, %rcx), %rdi
        neg     %rcx
1:
        mov     (%rsi, %rcx), %rax
        mov     %rax, (%rdi, %rcx)
        inc     %rcx
        jnz 1b
        .endm
