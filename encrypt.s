.section .note.GNU-stack, "", %progbits

.data
   string: .space 64
   key: .space 64
   stringBits: .space 448
   keyBits: .space 448
   n: .space 4
   m: .space 4
   vowels: .space 6
   formatString1: .asciz "%s"
   formatString2: .asciz "%[^\n]"
   formatStringPrint: .asciz "%s\n"
   formatInt: .asciz "%d "
   formatChar: .asciz "%c"
.text
.global main
main:
   # INITIALIZING THE VOWELS ARRAY
   #lea vowels, %edi

   # READING THE TWO INPUT STRINGS
   pushl $string
   pushl $formatString2
   call scanf
   addl $8, %esp
   pushl $key
   pushl $formatString1
   call scanf
   addl $8, %esp
   
   # GETTING THE LENGTHS OF THE TEXT AND ENCRYPTION KEY
   pushl $string
   call strlen
   addl $4, %esp
   movl %eax, n
   pushl $key
   call strlen
   addl $4, %esp
   movl %eax, m
   
   # 2 CASES:
   # a) n <= m (LENGTH OF TEXT <= LENGTH OF ENCRYPTION KEY)
   # b) n > m (LENGTH OF TEXT > LENGTH OF ENCRYPTION KEY)
   lea string, %esi
   lea key, %edi
   cmpl %eax, n
   jbe pre_vigenere
   
   xorl %ecx, %ecx
   xorl %ebx, %ebx
   
   # ADD CHARACTERS TO THE KEY SO IT MATCHES THE TEXT'S LENGTH 
   add_chars:
      cmpl n, %eax
      je pre_vigenere
      
      movb (%edi, %ecx, 1), %bl
      movb %bl, (%edi, %eax, 1)
      incl %ecx
      
      cmpl m, %ecx
      jne add_chars_final
      xorl %ecx, %ecx
      jmp add_chars_final
         
      add_chars_final:
         incl %eax
         jmp add_chars
   
# PRINT THE ENCRYPTION KEY FOR DEBUGGING PURPOSES
pre_vigenere:
   pushl $key
   pushl $formatStringPrint
   call printf
   pushl $0
   call fflush
   addl $12, %esp
   
   xorl %eax, %eax
   xorl %ebx, %ebx
   xorl %ecx, %ecx
   
# APPLY VIGENERE CIPHER TO THE ORIGINAL TEXT   
vigenere:
   cmpl %ecx, n
   je pre_update_bits
   
   # CHECK IF IT'S A LETTER (IF NOT, DON'T ENCRYPT)
   # 65 <= char <= 90 || 97 <= char <= 122
   movb (%esi, %ecx, 1), %al 
   cmpl $65, %eax
   jb vigenere_final
   cmpl $90, %eax
   jbe vigenere_cont_1
   cmpl $97, %eax
   jb vigenere_final
   cmpl $122, %eax
   ja vigenere_final
   
   # SOME COMMON OPERATIONS. CHECK IF THE CURRENT CHAR OF THE KEY
   # IS A LOWERCASE OR UPPERCASE
   vigenere_cont_1:
      movb (%edi, %ecx, 1), %bl
      xorl %edx, %edx
      subl $65, %ebx
      cmpl $31, %ebx
      jbe vigenere_cont_2
      subl $32, %ebx
   
   vigenere_cont_2:
      # CHECK IF THE CURRENT TEXT CHAR IS A LOWERCASE OR UPPERCASE
      cmpl $97, %eax
      jb vigenere_uppercase
   
   vigenere_lowercase:
      subl $97, %eax
      addl %ebx, %eax
      movl $26, %ebx
      divl %ebx
      addl $97, %edx
      movl %edx, %eax
      jmp vigenere_final

   vigenere_uppercase:
      subl $65, %eax
      addl %ebx, %eax
      movl $26, %ebx
      divl %ebx
      addl $65, %edx
      movl %edx, %eax
   
   vigenere_final:
      movb %al, (%esi, %ecx, 1)
      incl %ecx
      jmp vigenere
   
pre_update_bits:
   xorl %ecx, %ecx
   xorl %eax, %eax
   
update_bits:
   # FOR BOTH STRINGS (ENCRYPTED TEXT AND KEY): STORE THE VALUES OF
   # EVERY LETTER IN BINARY. ENCRYPT THE BITS USING THE RULES
   cmpl %ecx, n
   je pre_print_encrypted_string
   
   # CHECK IF IT'S A LETTER. IF NOT, DON'T ENCRYPT/CALCULATE BITS.
   xorl %ebx, %ebx
   movb (%esi, %ecx, 1), %bl
   cmpl $65, %ebx
   jb update_bits_final
   cmpl $90, %ebx
   jbe update_bits_cont
   cmpl $97, %ebx
   jb update_bits_final
   cmpl $122, %ebx
   ja update_bits_final
   
   # IT IS A LETTER. GET THE LETTER OF THE KEY AND START WORKING ON BITS
   # IDEA: CHECK IF THE CURRENT CASE IS VV / VC / CV / CC.
   # IF IT'S VV OR CC, CALL POWERS_OF_2 AND THEN ENCRYPT BITS.
   # IF IT'S CV OR VC, IT'S REDUNDANT TO CALL POWERS_OF_2. JUST ADD $7 TO %EAX (POWERS_OF_2 WOULD HAVE DONE THAT) AND THEN ENCRYPT BITS.
   # IT'S BECAUSE OF THE ENCRYPTION RULES. READ THE ALGORITHM IDEA.
   update_bits_cont:
      xorl %edx, %edx
      movb (%edi, %ecx, 1), %dl # GET THE CURRENT LETTER OF THE KEY
     
      pushl %ecx # MUST KEEP ECX'S VALUE
      
      pushl %edx
      pushl %ebx
      pushl %eax # MUST KEEP THE SIZE OF THE BITS ARRAYS (STORED IN EAX)
      call vowel_or_consonant
      
      # %EAX CONTAINS THE CASE CODE (0-3)
      # 0 = VV, 3 = CC => CALCULATE THE BITS AND PERFORM `AND` OPERATION
      # 1 = VC, 2 = CV => DON'T REDUNDANTLY CALCULATE THE BITS
      # CHECK THE CASE RULES TO UNDERSTAND
      debug:
         movl %eax, %ecx # %ECX WILL NOW STORE THE CASE CODE
         popl %eax # RESTORE THE SIZE OF THE BIT-ARRAYS
         pushl %ecx # LOAD THE CASE CODE ONTO THE STACK
         
         lea stringBits, %esi
         lea keyBits, %edi
         
         cmpl $0, %ecx
         je call_powers_of_2
         cmpl $3, %ecx
         je call_powers_of_2
         
         # BECAUSE THE CASE IS NOT 0 OR 3 (VV OR CC), IT WILL SKIP POW_OF_2
         # THAT MEANS THE BIT-ARRAY'S SIZE WON'T INCREASE 
         # WE HAVE TO ADD 7 TO THE LENGTH OURSELVES
         addl $7, %eax
         jmp call_encrypt_bits
      
      call_powers_of_2:
         # WE WILL NOW PUSH %EAX. THE STACK BECOMES THE FOLLOWING:
         # 8(%ebp) = %eax (CURRENT SIZE OF THE BITS ARRAY)
         # 12(%ebp) = %ecx (CURRENT CASE CODE)
         # 16(%ebp) = %ebx (CURRENT TEXT CHARACTER)
         # 20(%ebp) = %edx (CURRENT KEY CHARACTER)
         # 24(%ebp) = OLD %ecx (COUNTER FOR THE MAIN PROCEDURE)
         pushl %eax 
         call powers_of_2
         addl $4, %esp
   
      call_encrypt_bits:
         # WE WILL NOW PUSH %EAX. THE STACK BECOMES THE FOLLOWING:
         # 8(%ebp) = %eax (CURRENT SIZE OF THE BIT-ARRAYS)
         # 12(%ebp) = %ecx (CURRENT CASE CODE)
         # 16(%ebp) = %ebx (CURRENT TEXT CHARACTER)
         # 20(%ebp) = %edx (CURRENT KEY CHARACTER)
         # 24(%ebp) = OLD %ecx (COUNTER FOR THE MAIN PROCEDURE)
         pushl %eax
         call encrypt_bits
         popl %eax      # RESTORE THE SIZE OF THE BIT-ARRAYS
         addl $12, %esp # WE DON'T NEED THE CASE CODE OR LETTERS ANYMORE
         popl %ecx      # RESTORE THE COUNTER 
   
   update_bits_final:
      lea string, %esi
      lea key, %edi
      incl %ecx
      jmp update_bits
      
pre_print_encrypted_string:
   # %eax = NUMBER OF BITS IN THE ARRAY
   xorl %ecx, %ecx
   xorl %edx, %edx
   xorl %ebx, %ebx
   movl $64, m
   movl $0, n

print_encrypted_string:
   # CHECK IF THE CURRENT CHARACTER OF THE STRING IS A LETTER OR NOT
   # (CURRENT CHARACTER AFTER VIGENERE CIPHER ENCRYPTION)
   movl n, %ebx
   movb (%esi, %ebx, 1), %bl
      
   cmpl $65, %ebx
   jb print_encrypted_string_pre_final
   cmpl $90, %ebx
   jbe print_encrypted_string_pre_for
   cmpl $97, %ebx
   jb print_encrypted_string_pre_final
   cmpl $122, %ebx
   ja print_encrypted_string_pre_final
   
   # IT IS A LETTER, SO RESET THE VALUE IN %EBX
   print_encrypted_string_pre_for:
      xorl %ebx, %ebx
      lea stringBits, %esi
   
   print_encrypted_string_for:
      cmpl $7, %ecx
      je print_encrypted_string_final
      
      # IF THE CURRENT BIT IS 0, DON'T ADD THAT POWER OF 2
      cmpb $0, (%esi, %edx, 1)
      je print_encrypted_string_for_cont
      
      addl m, %ebx
      
      print_encrypted_string_for_cont:
         incl %ecx
         incl %edx
         shrl $1, m
         jmp print_encrypted_string_for
         
   print_encrypted_string_pre_final:
      # IF THE CHARACTER IS NOT A LETTER, PRINT THE ORIGINAL CHARACTER
      movl n, %ebx
      movb (%esi, %ebx, 1), %bl
      
   print_encrypted_string_final:
      pushl %eax
      pushl %edx
      
      pushl %ebx
      pushl $formatChar
      call printf
      pushl $0
      call fflush
      addl $12, %esp
    
      popl %edx
      popl %eax
   
      lea string, %esi
      movl $64, m
      incl n
      xorl %ecx, %ecx
      xorl %ebx, %ebx
      cmpl %edx, %eax
      je exit
      
      jmp print_encrypted_string
   
vowel_or_consonant:
   pushl %ebp
   movl %esp, %ebp
   
   # 8(%ebp) = THE SIZE OF THE BITS ARRAY (WON'T BE USED)
   # 12(%ebp) = CURRENT CHARACTER IN OUR TEXT
   # 16(%ebp) = CURRENT CHARACTER IN OUR KEY
   
   movl 12(%ebp), %eax
   movl 16(%ebp), %ebx
   cmpl $97, %eax
   jb vowel_or_consonant_XX
   subl $32, %eax
   
   vowel_or_consonant_XX:
      # IS THE CURRENT TEXT CHAR A VOWEL OR A CONSONANT?
      # EAX IS CURRENTLY LOWERCASE. MAKE EBX LOWERCASE AS WELL
      cmpl $97, %ebx
      jb vowel_or_consonant_XX_cont
      subl $32, %ebx
      
      vowel_or_consonant_XX_cont:
         cmpl $65, %eax # 'A' = 65
         je vowel_or_consonant_VX
         cmpl $69, %eax # 'E' = 69
         je vowel_or_consonant_VX
         cmpl $73, %eax # 'I' = 73
         je vowel_or_consonant_VX
         cmpl $79, %eax # 'O' = 79
         je vowel_or_consonant_VX
         cmpl $85, %eax # 'U' = 85
         jne vowel_or_consonant_CX
      
   vowel_or_consonant_VX:
      # IS THE CURRENT KEY CHAR A VOWEL OR A CONSONANT?
      cmpl $65, %ebx # A
      je vowel_or_consonant_VV
      cmpl $69, %ebx # E
      je vowel_or_consonant_VV
      cmpl $73, %ebx # 
      je vowel_or_consonant_VV
      cmpl $79, %ebx # O
      je vowel_or_consonant_VV
      cmpl $85, %ebx # U
      jne vowel_or_consonant_VC
         
   vowel_or_consonant_VV:
      # CASE VV = CODE 0
      xorl %eax, %eax
      jmp vowel_or_consonant_final
   
   vowel_or_consonant_CX:
      # IS THE CURRENT KEY CHAR A VOWEL OR A CONSONANT?
      cmpl $65, %ebx
      je vowel_or_consonant_CV
      cmpl $69, %ebx
      je vowel_or_consonant_CV
      cmpl $73, %ebx
      je vowel_or_consonant_CV
      cmpl $79, %ebx
      je vowel_or_consonant_CV
      cmpl $85, %ebx
      je vowel_or_consonant_CV
      
   vowel_or_consonant_CC:
      # CASE CC = CODE 3
      movl $3, %eax
      jmp vowel_or_consonant_final
      
   vowel_or_consonant_CV:
      # CASE CV = CODE 2
      movl $2, %eax
      jmp vowel_or_consonant_final
   
   vowel_or_consonant_VC:
      # CASE VC = CODE 1
      movl $1, %eax
   
   vowel_or_consonant_final:
      popl %ebp
      ret
   
encrypt_bits:
   pushl %ebp
   movl %esp, %ebp
   
   # 8(%ebp) = CURRENT SIZE OF THE BITS ARRAY
   # 12(%ebp) = CURRENT CASE CODE
   # 16(%ebp) = CURRENT TEXT CHARACTER
   # 20(%ebp) = CURRENT KEY CHARACTER
   
   # IT'S REDUNDANT TO CHECK WHETHER IT'S A LETTER OR NOT
   # THAT HAS ALREADY BEEN DONE IN THE MAIN PROCEDURE
   
   # CHECK THE CASE
   movl 12(%ebp), %ecx
   cmpl $0, %ecx
   je case_VV
   cmpl $1, %ecx
   #je encrypt_bits_final
   je count_powers
   cmpl $2, %ecx
   #je encrypt_bits_final
   je count_powers
   
   # IT'S $3, SO THE CASE IS CC, BUT THAT IS THE SAME AS VV.
   # LET THE CC CASE GO FORWARDS TO CASE_VV.
   
   case_VV:
      # VV => stringBits & keyBits
      movl 8(%ebp), %ecx 
      decl %ecx
      movl 8(%ebp), %edx
      subl $7, %edx
      
      case_VV_for:
         cmpl %edx, %ecx
         jl encrypt_bits_final
         
         xorl %eax, %eax
         movb (%esi, %ecx, 1), %al
         xorl %ebx, %ebx
         movb (%edi, %ecx, 1), %bl
         and %ebx, %eax
         movb %al, (%esi, %ecx, 1)
         
         decl %ecx
         jmp case_VV_for
      
   count_powers:
      # A LETTER WILL ALWAYS CONTAIN THE POWER 2^6 = 64.
      # USE %ECX TO COUNT THE NUMBER OF 1'S
      movl 20(%ebp), %ebx # STORE THE KEY CHAR
      movl $32, m
      movl $1, %ecx
      subl $64, %ebx
      
      count_powers_for:
         cmpl $0, m
         je count_powers_final
         
         subl m, %ebx
         cmpl $0, %ebx
         jge count_powers_for_cont
         
         addl m, %ebx
         decl %ecx
         
         count_powers_for_cont:
            incl %ecx
            shrl $1, m
            jmp count_powers_for
      
      count_powers_final:
      # WE NOW HAVE THE NUMBER OF 1'S IN KEYBITS (STORED IN %ECX)
      # TO GET THE NUMBER OF 0'S, SUBTRACT NUMBER OF 1'S FROM 7.
      # VC (CASE 1) => stringBits - count(1 in keyBits)
      # CV (CASE 2) => stringBits - count(0 in keyBits)
      movl 16(%ebp), %eax # GET THE TEXT LETTER
      movl 12(%ebp), %edx # GET THE CASE CODE
      cmpl $1, %edx
      je case_VC
      
      case_CV: # CASE 2, SUBTRACT NUMBER OF 0's
         subl $7, %eax
         addl %ecx, %eax
         jmp pre_conversion
         
      case_VC: # CASE 1, SUBTRACT NUMBER OF 1'S
         subl %ecx, %eax
         
      pre_conversion:
         movl 8(%ebp), %edx
         movl 8(%ebp), %ecx
         subl $7, %ecx
         movl $64, m
      
      # %EAX HAS THE CURRENT VALUE TO BE CONVERTED TO BINARY
      # STORE THE BITS IN %ESI
      convert_to_binary:
         cmpl %ecx, %edx
         je encrypt_bits_final
         
         subl m, %eax
         cmpl $0, %eax
         jge convert_to_binary_1
         
         convert_to_binary_0:
            addl m, %eax
            movb $0, (%esi, %ecx, 1)
            jmp convert_to_binary_cont
            
         convert_to_binary_1:
            movb $1, (%esi, %ecx, 1)
            
         convert_to_binary_cont:
            shrl $1, m
            incl %ecx
            jmp convert_to_binary
        
   encrypt_bits_final:
      #movl 8(%ebp), %eax
      popl %ebp
      ret
   
powers_of_2:
   pushl %ebp
   movl %esp, %ebp
   
   # 8(%ebp) = CURRENT SIZE OF THE BITS ARRAY
   # 12(%ebp) = CURRENT CASE CODE (PUSHED ONLY TO SAVE ITS VALUE)
   # 16(%ebp) = CURRENT TEXT CHARACTER
   # 20(%ebp) = CURRENT KEY CHARACTER
   
   movl 8(%ebp), %ecx
   movl %ecx, %edx
   addl $7, %edx
   movl 16(%ebp), %eax
   movl 20(%ebp), %ebx
   
   movb $1, (%esi, %ecx, 1)
   movb $1, (%edi, %ecx, 1)
   incl %ecx
   subl $64, %eax
   subl $64, %ebx
   movl $32, m
   
   powers_of_2_for:
      cmpl %ecx, %edx
      je powers_of_2_final
      
      subl m, %eax
      subl m, %ebx
      
      cmpl $0, %eax
      jl powers_of_2_cont_1
      movb $1, (%esi, %ecx, 1)
      jmp powers_of_2_cont_2
      
      powers_of_2_cont_1:
         addl m, %eax
         movb $0, (%esi, %ecx, 1)
         
      powers_of_2_cont_2:
         cmpl $0, %ebx
         jl powers_of_2_cont_3
         movb $1, (%edi, %ecx, 1)
         jmp powers_of_2_for_final
         
      powers_of_2_cont_3:
         addl m, %ebx
         movb $0, (%edi, %ecx, 1)
         
      powers_of_2_for_final:
         incl %ecx
         shrl $1, m
         jmp powers_of_2_for
   
   powers_of_2_final:
      movl %ecx, %eax
      popl %ebp
      ret
   
exit:   
   movl $1, %eax
   movl $0, %ebx
   int $0x80
