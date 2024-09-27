.section .note.GNU-stack, "", %progbits

.data
   string: .space 64
   key: .space 64
   n: .space 4
   m: .space 4
   stringBits: .space 448
   keyBits: .space 448
   vowels: .space 6
   formatString1: .asciz "%s"
   formatString2: .asciz "%[^\n]"
   formatInt: .asciz "%d\n"
   formatStringPrint: .asciz "%s\n"
   formatChar: .asciz "%c"
   
.text

.global main

main:
   # READ INPUT - 0 FOR ENCRYPTION, 1 FOR DECRYPTION
   pushl $n
   pushl $formatInt
   call scanf
   addl $8, %esp
   
   cmpb $1, n
   je main_decrypt
   
main_encrypt:
   # READING THE TWO INPUT STRINGS
   leal string, %eax
   pushl %eax
   pushl $formatString2
   call scanf
   addl $8, %esp
   
   leal key, %eax
   pushl %eax
   pushl $formatString1
   call scanf
   addl $8, %esp
   
   # GETTING THE LENGTHS OF THE TEXT AND ENCRYPTION KEY
   leal string, %esi
   leal key, %edi
   
   pushl %esi
   call strlen
   addl $4, %esp
   
   movb %al, n
   
   pushl %edi
   call strlen
   addl $4, %esp
   movb %al, m
   
   # 2 CASES:
   # a) n <= m (LENGTH OF TEXT <= LENGTH OF ENCRYPTION KEY)
   # b) n > m (LENGTH OF TEXT > LENGTH OF ENCRYPTION KEY) => REPEAT THE TEXT
   cmpb %al, n
   jbe pre_vigenere
   
   xorl %ecx, %ecx
   xorl %ebx, %ebx
   
   # ADD CHARACTERS TO THE KEY SO IT MATCHES THE TEXT'S LENGTH 
   add_chars:
      cmpb n, %al
      je pre_vigenere
      
      movb (%edi, %ecx, 1), %bl
      movb %bl, (%edi, %eax, 1)
      incb %cl
      
      cmpb m, %cl
      jne add_chars_final
      xorb %cl, %cl
         
      add_chars_final:
         incb %al
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
   xorb %bl, %bl
   xorl %ecx, %ecx
   
# APPLY VIGENERE CIPHER TO THE ORIGINAL TEXT   
vigenere:
   cmpb n, %cl
   je pre_update_bits
   
   # CHECK IF IT'S A LETTER (IF NOT, DON'T ENCRYPT)
   # 65 <= char <= 90 || 97 <= char <= 122
   movb (%esi, %ecx, 1), %al 
   cmpb $65, %al
   jb vigenere_final
   cmpb $90, %al
   jbe vigenere_cont_1
   cmpb $97, %al
   jb vigenere_final
   cmpb $122, %al
   ja vigenere_final
   
   # IT IS A LETTER. CHECK IF THE CURRENT CHAR OF THE KEY IS LOWERCASE OR UPPERCASE
   vigenere_cont_1:
      movb (%edi, %ecx, 1), %bl
      xorl %edx, %edx # PREPARING FOR DIVISION
      subb $65, %bl
      cmpb $31, %bl
      jbe vigenere_cont_2
      subb $32, %bl
   
   vigenere_cont_2:
      # CHECK IF THE CURRENT TEXT CHAR IS A LOWERCASE OR UPPERCASE
      cmpb $97, %al
      jb vigenere_uppercase
   
   vigenere_lowercase:
      subb $97, %al
      addb %bl, %al
      movb $26, %bl
      divl %ebx
      addb $97, %dl
      movb %dl, %al
      jmp vigenere_final

   vigenere_uppercase:
      subb $65, %al
      addb %bl, %al
      movb $26, %bl
      divl %ebx
      addb $65, %dl
      movb %dl, %al
   
   vigenere_final:
      movb %al, (%esi, %ecx, 1)
      incb %cl
      jmp vigenere
   
pre_update_bits:
   xorb %cl, %cl
   xorb %al, %al
   
update_bits:
   # PERFORM OPERATIONS ON THE BITS FOR FURTHER ENCRYPTION
   cmpb n, %cl
   je pre_print_encrypted_string
   
   # CHECK IF THE CURRENT TEXT CHAR IS A LETTER. 
   # IF NOT, SKIP IT
   xorl %ebx, %ebx
   movb (%esi, %ecx, 1), %bl
   cmpb $65, %bl
   jb update_bits_final
   cmpb $90, %bl
   jbe update_bits_cont
   cmpb $97, %bl
   jb update_bits_final
   cmpb $122, %bl
   ja update_bits_final
   
   # IT IS A LETTER. START ENCRYPTING THE BITS.
   # CHECK IF THE CURRENT CASE IS VV / VC / CV / CC.
   # IF IT'S VV OR CC, CALL POWERS_OF_2 AND THEN ENCRYPT BITS.
   # IF IT'S CV OR VC, IT'S REDUNDANT TO CALL POWERS_OF_2. JUST ADD $7 TO %EAX (POWERS_OF_2 WOULD HAVE DONE THAT) AND THEN ENCRYPT BITS.
   # IT'S BECAUSE OF THE ENCRYPTION RULES. READ THE ALGORITHM IDEA.
   update_bits_cont:
      xorl %edx, %edx
      movb (%edi, %ecx, 1), %dl # GET THE CURRENT LETTER OF THE KEY
     
      pushl %ecx # MUST KEEP ECX'S VALUE
      
      # GET THE CURRENT VOWEL-CONSONANT CASE (VV, VC, CV, CC)
      # PUSH %EAX TO SAVE THE VALUE FOR THE FUTURE
      pushl %edx
      pushl %ebx
      pushl %eax
      call vowel_or_consonant
      
      # %EAX CONTAINS THE CASE CODE (0-3)
      # 0 = VV, 3 = CC => CALCULATE THE BITS AND PERFORM `AND` OPERATION
      # 1 = VC, 2 = CV => DON'T REDUNDANTLY CALCULATE THE BITS
      
      movl %eax, %ecx # %ECX WILL NOW STORE THE CASE CODE
      popl %eax       # RESTORE THE SIZE OF THE BIT-ARRAYS
      pushl %ecx      # LOAD THE CASE CODE ONTO THE STACK
         
      leal stringBits, %esi
      leal keyBits, %edi
         
      cmpb $0, %cl
      je call_powers_of_2
      cmpb $3, %cl
      je call_powers_of_2
         
      # BECAUSE THE CASE IS NOT 0 OR 3 (VV OR CC), IT WILL SKIP POW_OF_2
      # THAT MEANS THE SIZE OF THE BIT-ARRAYS WON'T INCREASE 
      # WE HAVE TO MANUALLY ADD 7 TO THE SIZE
      addw $7, %ax
      jmp call_encrypt_bits
      
      call_powers_of_2:
         # WE WILL NOW PUSH %EAX. THE STACK BECOMES THE FOLLOWING:
         # 8(%ebp)  = %eax (CURRENT SIZE OF THE BITS ARRAY)
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
      leal string, %esi
      leal key, %edi
      incb %cl
      jmp update_bits
      
pre_print_encrypted_string:
   # %eax = NUMBER OF BITS IN THE ARRAY
   xorl %ecx, %ecx
   xorl %edx, %edx
   movl $64, m
   movb $0, n

print_encrypted_string:
   # CHECK IF THE CURRENT CHARACTER OF THE STRING IS A LETTER OR NOT
   # (CURRENT CHARACTER AFTER VIGENERE CIPHER ENCRYPTION)
   movl n, %ebx
   movb (%esi, %ebx, 1), %bl
      
   cmpb $65, %bl
   jb print_encrypted_string_pre_final
   cmpb $90, %bl
   jbe print_encrypted_string_pre_for
   cmpb $97, %bl
   jb print_encrypted_string_pre_final
   cmpb $122, %bl
   ja print_encrypted_string_pre_final
   
   # IT IS A LETTER, SO RESET THE VALUE IN %EBX
   # %EBX WILL BE USED TO TURN IT FROM BINARY TO TEXT
   print_encrypted_string_pre_for:
      xorl %ebx, %ebx
      leal stringBits, %esi
   
   print_encrypted_string_for:
      cmpb $7, %cl
      je print_encrypted_string_final
      
      # IF THE CURRENT BIT IS 0, DON'T ADD THAT POWER OF 2
      cmpb $0, (%esi, %edx, 1)
      je print_encrypted_string_for_cont
      
      addb m, %bl
      
      print_encrypted_string_for_cont:
         incb %cl
         incw %dx
         shrb $1, m
         jmp print_encrypted_string_for
         
   print_encrypted_string_pre_final:
      # IF THE CHARACTER IS NOT A LETTER, PRINT THE ORIGINAL CHARACTER
      movb n, %bl
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
   
      leal string, %esi
      movb $64, m
      incb n
      xorb %cl, %cl
      xorb %bl, %bl
      cmpw %dx, %ax
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
   cmpb $97, %al
   jb vowel_or_consonant_XX
   subb $32, %al
   
   vowel_or_consonant_XX:
      # IS THE CURRENT TEXT CHAR A VOWEL OR A CONSONANT?
      # EAX IS CURRENTLY LOWERCASE. MAKE EBX LOWERCASE AS WELL
      cmpb $97, %bl
      jb vowel_or_consonant_XX_cont
      subb $32, %bl
      
      vowel_or_consonant_XX_cont:
         cmpb $65, %al # 'A' = 65
         je vowel_or_consonant_VX
         cmpb $69, %al # 'E' = 69
         je vowel_or_consonant_VX
         cmpb $73, %al # 'I' = 73
         je vowel_or_consonant_VX
         cmpb $79, %al # 'O' = 79
         je vowel_or_consonant_VX
         cmpb $85, %al # 'U' = 85
         jne vowel_or_consonant_CX
      
   vowel_or_consonant_VX:
      # IS THE CURRENT KEY CHAR A VOWEL OR A CONSONANT?
      cmpb $65, %bl # A
      je vowel_or_consonant_VV
      cmpb $69, %bl # E
      je vowel_or_consonant_VV
      cmpb $73, %bl # I
      je vowel_or_consonant_VV
      cmpb $79, %bl # O
      je vowel_or_consonant_VV
      cmpb $85, %bl # U
      jne vowel_or_consonant_VC
         
   vowel_or_consonant_VV:
      # CASE VV = CODE 0
      xorb %al, %al
      jmp vowel_or_consonant_final
   
   vowel_or_consonant_CX:
      # IS THE CURRENT KEY CHAR A VOWEL OR A CONSONANT?
      cmpb $65, %bl
      je vowel_or_consonant_CV
      cmpb $69, %bl
      je vowel_or_consonant_CV
      cmpb $73, %bl
      je vowel_or_consonant_CV
      cmpb $79, %bl
      je vowel_or_consonant_CV
      cmpb $85, %bl
      je vowel_or_consonant_CV
      
   vowel_or_consonant_CC:
      # CASE CC = CODE 3
      movb $3, %al
      jmp vowel_or_consonant_final
      
   vowel_or_consonant_CV:
      # CASE CV = CODE 2
      movb $2, %al
      jmp vowel_or_consonant_final
   
   vowel_or_consonant_VC:
      # CASE VC = CODE 1
      movb $1, %al
   
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
   cmpb $0, %cl
   je case_VV
   cmpb $1, %cl
   je count_powers
   cmpb $2, %cl
   je count_powers
   
   # IT'S 3 (CC), BUT THAT IS THE SAME AS VV.
   # LET THE CC CASE GO FORWARDS TO CASE_VV.
   
   case_VV:
      # VV => stringBits = (stringBits & keyBits)
      movw 8(%ebp), %cx
      decw %cx
      movl 8(%ebp), %edx
      subw $7, %dx
      
      case_VV_for:
         cmpw %dx, %cx
         jl encrypt_bits_final
         
         xorl %eax, %eax
         movb (%esi, %ecx, 1), %al
         xorl %ebx, %ebx
         movb (%edi, %ecx, 1), %bl
         andb %bl, %al
         movb %al, (%esi, %ecx, 1)
         
         decw %cx
         jmp case_VV_for
      
   count_powers:
      # A LETTER WILL ALWAYS CONTAIN THE POWER 2^6 = 64.
      # USE %ECX TO COUNT THE NUMBER OF 1'S
      movl 20(%ebp), %ebx # STORE THE KEY CHAR
      movl $32, m
      movw $1, %cx
      subb $64, %bl
      
      count_powers_for:
         cmpb $0, m
         je count_powers_final
         
         subl m, %ebx
         cmpl $0, %ebx
         jge count_powers_for_cont
         
         addl m, %ebx
         decb %cl
         
         count_powers_for_cont:
            incb %cl
            shrb $1, m
            jmp count_powers_for
      
      count_powers_final:
      # WE NOW HAVE THE NUMBER OF 1'S IN KEYBITS (STORED IN %ECX)
      # TO GET THE NUMBER OF 0'S, SUBTRACT NUMBER OF 1'S FROM 7.
      # VC (CASE 1) => stringBits - count(1 in keyBits)
      # CV (CASE 2) => stringBits - count(0 in keyBits)
      movl 16(%ebp), %eax # GET THE TEXT LETTER
      movl 12(%ebp), %edx # GET THE CASE CODE
      cmpb $1, %dl
      je case_VC
      
      case_CV: # CASE 2, SUBTRACT NUMBER OF 0's
         subb $7, %al
         addb %cl, %al
         jmp pre_conversion
         
      case_VC: # CASE 1, SUBTRACT NUMBER OF 1'S
         subb %cl, %al
         
      pre_conversion:
         movw 8(%ebp), %dx
         movw 8(%ebp), %cx
         subw $7, %cx
         movl $64, m
      
      # %EAX HAS THE CURRENT VALUE TO BE CONVERTED TO BINARY
      # STORE THE BITS IN %ESI
      convert_to_binary:
         cmpw %cx, %dx
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
            shrb $1, m
            incw %cx
            jmp convert_to_binary
        
   encrypt_bits_final:
      popl %ebp
      ret
   
powers_of_2:
   pushl %ebp
   movl %esp, %ebp
   
   # 8(%ebp) = CURRENT SIZE OF THE BITS ARRAY
   # 12(%ebp) = CURRENT CASE CODE (WON'T NEED IT, PUSHED ONLY TO SAVE ITS VALUE)
   # 16(%ebp) = CURRENT TEXT CHARACTER
   # 20(%ebp) = CURRENT KEY CHARACTER
   
   movl 8(%ebp), %ecx
   movl %ecx, %edx
   addw $7, %dx
   movl 16(%ebp), %eax
   movl 20(%ebp), %ebx
   
   movb $1, (%esi, %ecx, 1)
   movb $1, (%edi, %ecx, 1)
   incw %cx
   subb $64, %al
   subb $64, %bl
   movl $32, m
   
   powers_of_2_for:
      cmpw %cx, %dx
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
         incw %cx
         shrb $1, m
         jmp powers_of_2_for
   
   powers_of_2_final:
      movw %cx, %ax
      popl %ebp
      ret
      
# INPUT = 1 => PERFORM DECRYPTION
# (todo)
main_decrypt:
   
exit:   
   movl $1, %eax
   movl $0, %ebx
   int $0x80
