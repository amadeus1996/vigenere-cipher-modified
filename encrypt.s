.section .note.GNU-stack, "", %progbits

.data
   string: .space 64
   key: .space 64
   vowels: .space 64
   n: .space 4
   m: .space 4
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

   # STORE VALUE FOR LATER 
   pushl n
   
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

   # BEFORE ENCRYPTING/DECRYPTING, THE TEXT/KEY LENGTHS HAVE TO MATCH EACHOTHER
   # GET THE LENGTHS OF THE TEXT AND ENCRYPTION KEY
   leal string, %esi
   leal key, %edi
   
   pushl %esi
   call strlen
   addl $4, %esp
   
   # n = LENGTH OF TEXT
   movb %al, n
   
   pushl %edi
   call strlen
   addl $4, %esp

   # m = LENGTH OF KEY
   movb %al, m

   # 2 CASES:
   # a) n <= m (LENGTH OF TEXT <= LENGTH OF ENCRYPTION KEY)
   # b) n > m (LENGTH OF TEXT > LENGTH OF ENCRYPTION KEY) => REPEAT THE KEY
   cmpb %al, n
   jbe encrypt_or_decrypt
   
   # THEY ARE NOT EQUAL
   # ADD CHARACTERS TO THE KEY SO IT MATCHES THE TEXT'S LENGTH 
   xorl %ecx, %ecx
   xorl %ebx, %ebx
   
   add_chars:
      cmpb n, %al
      je encrypt_or_decrypt
      
      movb (%edi, %ecx, 1), %bl
      movb %bl, (%edi, %eax, 1)
      incb %cl
      
      cmpb m, %cl
      jne add_chars_final
      xorb %cl, %cl
         
      add_chars_final:
         incb %al
         jmp add_chars
   
encrypt_or_decrypt:
   # RESTORE THE PUSHED 0/1 VALUE
   popl %edx
   cmpb $1, %dl
   je decrypt 

encrypt:
   xorl %ecx, %ecx 

   encrypt_for:
      cmpb n, %cl 
      je print_string

      # CHECK IF THE CURRENT textChar IS A LETTER
      # 65 <= char <= 90 || 97 <= char <= 122
      xorl %ebx, %ebx
      movb (%esi, %ecx, 1), %bl 
      cmpb $65, %bl
      jb encrypt_final
      cmpb $90, %bl
      jbe encrypt_for_cont
      cmpb $97, %bl
      jb encrypt_final
      cmpb $122, %bl
      ja encrypt_final

      encrypt_for_cont:
         # IT IS A LETTER
         # APPLY VIGENERE CIPHER AND THEN ENCRYPT THE BITS

         xorl %edx, %edx 
         movb (%edi, %ecx, 1), %dl # keyChar
         pushl %ecx # STORE THE COUNTER

         pushl $0
         pushl %edx 
         pushl %ebx 
         call vigenere # ENCRYPT THE CURRENT LETTER USING VIGENERE
         addl $4, %esp 
         # HAVEN'T POPPED %edx OR $0 YET, SAVING THE VALUE FOR %edx

         # %eax = vigenere-encryptedChar
         # SAVE IT SOMEWHERE
         movl %eax, m

         # CHECK IF vigenere-encryptedChar IS A VOWEL OR A CONSONANT (0/1)
         pushl %eax 
         call check_vowel_consonant
         addl $4, %esp
         movl %eax, %ecx # STORE THE RESULT IN %ecx

         # CHECK IF keyChar IS A VOWEL OR A CONSONANT (0/1)
         popl %edx 
         addl $4, %esp 
         pushl %edx 
         call check_vowel_consonant 
         popl %edx 

         # %ebx = vigenere-encryptedChar
         # %ecx = 0/1 of %ebx
         # %eax = 0/1 of keyChar 
         # CHECK THE CASE (VV=0, VC=1, CV=2, CC=3)

         pushl %eax 
         pushl %ecx 
         call check_case # %eax = CASE CODE
         addl $8, %esp 
         pushl %eax # PUSH THE CASE CODE ONTO THE STACK AS AN ARGUMENT FOR encrypt_bits

         # GET THE NUMBER OF 1'S IN keyChar
         pushl %edx 
         call count_bits # %eax = NUMBER OF 1'S
         popl %edx 

         # CALL ENCRYPT_BITS (IT HAS 4 ARGUMENTS)
         # ONE OF THEM HAS ALREADY BEEN PUSHED ABOVE => 20(%ebp) = CASE CODE
         # PUSH vigenere-encryptedChar, keyChar, NUMBER OF 1'S
         pushl %eax # NUMBER OF 1'S
         pushl %edx # keyChar
         pushl m    # vigenere-encryptedChar
         call encrypt_bits 
         addl $16, %esp
         
         # %eax = FINAL ENCRYPTED LETTER
         popl %ecx # RESTORE THE COUNTER TO UPDATE THE CURRENT LETTER
         movb %al, (%esi, %ecx, 1)

      encrypt_final:
         incb %cl 
         jmp encrypt_for

encrypt_bits:
   pushl %ebp 
   movl %esp, %ebp 

   # 8(%ebp)  = vigenere-encryptedChar
   # 12(%ebp) = keyChar
   # 16(%ebp) = NUMBER OF 1'S
   # 20(%ebp) = CASE CODE 

   movl 8(%ebp), %ebx 
   movl 16(%ebp), %ecx 
   movl 20(%ebp), %eax 

   cmpb $1, %al 
   je encrypt_bits_VC
   cmpb $2, %al 
   je encrypt_bits_CV

   encrypt_bits_VV_CC:
      movl 12(%ebp), %edx # keyChar
      movb $64, %al       # STORE THE SUM IN %eax 
      subb %al, %bl 
      subb %al, %dl
      movl $32, m

      encrypt_bits_VV_CC_for:
         cmpl $0, m 
         je encrypt_bits_VV_CC_final 

         xorl %ecx, %ecx 
         subl m, %ebx 
         subl m, %edx 

         cmpl $0, %ebx 
         jge encrypt_bits_VV_CC_for_cont 

         addl m, %ebx 
         incb %cl 

         encrypt_bits_VV_CC_for_cont:
            cmpl $0, %edx 
            jge encrypt_bits_VV_CC_for_xor

            addl m, %edx 
            incb %cl 

            encrypt_bits_VV_CC_for_xor:
               cmpb $1, %cl 
               jne encrypt_bits_VV_CC_for_final 

               addb m, %al 

         encrypt_bits_VV_CC_for_final:
            shrb $1, m 
            jmp encrypt_bits_VV_CC_for
      
      encrypt_bits_VV_CC_final:
         movb 20(%ebp), %cl  # CASE CODE
         movl 16(%ebp), %edx # NUMBER OF 1'S
         cmpb $0, %cl 
         je encrypt_bits_VV_CC_final_cont

         subb $7, %al 
         addb %dl, %al 
         addb %dl, %al 

         encrypt_bits_VV_CC_final_cont:
            subb %dl, %al 
            jmp encrypt_bits_final

   encrypt_bits_VC:
      movb %bl, %al 
      subb %cl, %al 
      jmp encrypt_bits_final

   encrypt_bits_CV:
      movb %bl, %al 
      subb $7, %al 
      addb %cl, %al 

   encrypt_bits_final:
      popl %ebp 
      ret

decrypt:
   # THEY ARE EQUAL => DECRYPTION
   # WE HAVE THE ENCRYPTED TEXT AND THE ENCRYPTION KEY
   # INPUT THE LETTERS STRING: 0=VOWEL, 1=CONSONANT, 2=OTHER
   leal vowels, %eax
   pushl %eax
   pushl $formatString1
   call scanf
   addl $8, %esp
   
   # PRINT FOR DEBUGGING PURPOSES
   leal key, %eax
   pushl %eax
   pushl $formatStringPrint
   call printf
   pushl $0
   call fflush
   addl $12, %esp

   # GO THROUGH EVERY TEXT CHARACTER. IF IT'S NOT A LETTER, SKIP
   # CHECK IF IT'S A VOWEL OR CONSONANT (USING THE VOWELS ARRAY)
   # CHECK IF THE CURRENT KEY CHAR IS A VOWEL OR CONSONANT
   # GET THE CASE (VV/VC/CV/CC)
   # FIND THE POST-VIGENERE ENCRYPTED TEXT
   xorl %ecx, %ecx

   decrypt_for:
      cmpb n, %cl
      je print_string

      leal vowels, %esi
      xorl %ebx, %ebx
      movb (%esi, %ecx, 1), %bl
      subb $48, %bl
      cmpb $2, %bl 
      je decrypt_final # IT'S NOT A LETTER

      xorl %edx, %edx
      movb (%edi, %ecx, 1), %dl  # GET THE KEY CHAR
      
      pushl %ecx # STORE THE COUNTER

      pushl %edx # PUSH THE keyChar
      call check_vowel_consonant # 0 => keyChar IS A VOWEL, 1 => keyChar IS A CONSONANT
      popl %edx
      
      pushl %eax # 0/1 FOR keyChar
      pushl %ebx # 0/1 FOR encryptedChar
      call check_case # 0=VV, 1=VC, 2=CV, 3=CC
      addl $8, %esp

      # %eax NOW STORES THE CASE CODE 
      # FOR ALL CASES THERE IS A COMMON RULE: THE NUMBER OF 1'S / 0'S
      # STORE %eax, CALL count_bits TO GET THE NUMBER OF 1'S IN keyChar
      pushl %eax # SAVE THE CASE CODE
      pushl %edx # FUNCTION ARGUMENT = THE LETTER (keyChar)
      call count_bits
      popl %edx 
      
      movl %eax, m # STORE THE NUMBER OF 1'S IN m 
      popl %eax    # RESTORE THE CASE CODE 

      leal string, %esi
      xorl %ebx, %ebx 
      popl %ecx                  # RESTORE THE COUNTER
      movb (%esi, %ecx, 1), %bl # GET encryptedChar
      pushl %ecx                 # STORE THE COUNTER AGAIN

      pushl m    # NUMBER OF 1'S
      pushl %eax # CASE CODE 
      pushl %edx # keyChar
      pushl %ebx # encryptedChar
      call decrypt_bits 
      popl %ebx 
      popl %edx 
      addl $8, %esp 

      pushl $1   # CODE FOR VIGENERE-DECRYPTION
      pushl %edx # keyChar
      pushl %eax # vigenere-encryptedChar
      call vigenere 
      addl $12, %esp

      debug_here:

      # STORE THE DECRYPTED LETTER
      popl %ecx # RESTORE THE COUNTER
      movb %al, (%esi, %ecx, 1)

      decrypt_final:
         incb %cl 
         jmp decrypt_for

vigenere:
   pushl %ebp 
   movl %esp, %ebp 

   # 8(%ebp)  = textChar (CODE=0) OR encryptedChar (CODE=1)
   # 12(%ebp) = keyChar
   # 16(%ebp) = CODE FOR VIGENERE-DECRYPTION

   movl 8(%ebp), %eax  # encryptedChar
   movl 12(%ebp), %ebx # keyChar
   movl 16(%ebp), %ecx # CODE

   # GET THE ALPHABET POSITION OF keyChar
   xorl %edx, %edx # PREPARING FOR DIVISION
   subb $65, %bl
   cmpb $31, %bl
   jbe vigenere_cont
   subb $32, %bl
   
   vigenere_cont:
      # CHECK IF THE CURRENT TEXT CHAR IS A LOWERCASE OR UPPERCASE
      cmpb $97, %al
      jb vigenere_uppercase
   
   vigenere_lowercase:
      subb $97, %al
      cmpb $1, %cl 
      je vigenere_lowercase_cont
      addb %bl, %al # FOR ENCRYPTION
      addb %bl, %al 

      vigenere_lowercase_cont:
         subl %ebx, %eax 
         cmpl $0, %eax
         jge vigenere_lowercase_cont_pos

         vigenere_lowercase_cont_neg:
            movl %eax, %ebx # %ebx = -X
            subl %ebx, %eax # -X - (-X) = 0
            subl %ebx, %eax # 0 - (-X) = X
            movl $26, %ebx
            divl %ebx 
            subb %dl, %bl 
            addb $97, %bl 
            movb %bl, %al 
            jmp vigenere_final

         vigenere_lowercase_cont_pos:
            movb $26, %bl 
            divl %ebx 
            addb $97, %dl 
            movb %dl, %al
            jmp vigenere_final

   vigenere_uppercase:
      subb $65, %al
      cmpb $1, %cl 
      je vigenere_uppercase_cont
      addb %bl, %al # FOR ENCRYPTION
      addb %bl, %al 

      vigenere_uppercase_cont:
         subl %ebx, %eax 
         cmpl $0, %eax
         jge vigenere_uppercase_cont_pos

         vigenere_uppercase_cont_neg:
            movl %eax, %ebx # %ebx = -X
            subl %ebx, %eax # -X - (-X) = 0
            subl %ebx, %eax # 0 - (-X) = X
            movl $26, %ebx
            divl %ebx 
            subb %dl, %bl 
            addb $65, %bl 
            movb %bl, %al 
            jmp vigenere_final

         vigenere_uppercase_cont_pos:
            movb $26, %bl
            divl %ebx
            addb $65, %dl
            movl %edx, %eax 

   vigenere_final:
      popl %ebp
      ret

decrypt_bits:
   pushl %ebp 
   movl %esp, %ebp

   # 20(%ebp) = NUMBER OF 1'S
   # 16(%ebp) = CASE CODE
   # 12(%ebp) = keyChar
   # 8(%ebp)  = encryptedChar

   movl 16(%ebp), %eax 
   movl 20(%ebp), %ecx 
   movl 8(%ebp), %ebx 
   addb %cl, %bl 
   cmpb $1, %al # CASE 0 OR 1 => ADD NUMBER OF 1'S, OTHERWISE ADD NUMBER OF 0'S
   jbe decrypt_bits_cont

   subb %cl, %bl # CANCEL THE LAST OPERATION
   addb $7, %bl 
   subb %cl, %bl # ADD 7 AND SUBSTRACT 1'S = NUMBER OF 0'S

   decrypt_bits_cont:
      # CASE 1 OR 2 => THE DECRYPTING IS FINISHED
      cmpb $1, %al 
      je decrypt_bits_VC_CV
      cmpb $2, %al 
      je decrypt_bits_VC_CV

      # CASE 3 OR 4 => vigenereBit ^ keyBit = encryptedBit, vigenereBit = ?
      # STORE THE SUM OF THE 2-POWERS (BITS) IN %eax
      # 2^6 WILL ALWAYS BE INCLUDED (ALL LETTERS > 64)
      movb $64, %al
      # movl 12(%ebp), %edx # GET keyChar 
      subb $64, %bl 
      subb $64, %dl 
      movb $32, %cl 

      decrypt_bits_for:
         # X ^ 0 = 0 => X = 0
         # X ^ 0 = 1 => X = 1
         # X ^ 1 = 0 => X = 1
         # X ^ 1 = 1 => X = 0
         # X = 0 IF SUM IS 0 OR 2, OTHERWISE X = 1
         cmpb $0, %cl 
         je decrypt_bits_final 

         movl $0, m
         subl %ecx, %ebx 
         subl %ecx, %edx 

         cmpl $0, %ebx 
         jge decrypt_bits_for_cont 

         incb m 
         addl %ecx, %ebx 

         decrypt_bits_for_cont:
            cmpl $0, %edx 
            jge decrypt_bits_for_xor

            incb m
            addl %ecx, %edx

         decrypt_bits_for_xor:
            cmpl $1, m 
            jne decrypt_bits_for_final 

            addb %cl, %al 

         decrypt_bits_for_final:
            shrb $1, %cl 
            jmp decrypt_bits_for 

   decrypt_bits_VC_CV:
      movb %bl, %al 

   decrypt_bits_final:
      popl %ebp 
      ret

count_bits:
   pushl %ebp 
   movl %esp, %ebp 

   # 8(%ebp) = ASCII FOR THE KEY LETTER 
   movl 8(%ebp), %ebx 
   subb $64, %bl # LETTERS WILL ALWAYS HAVE 2^6
   movl $1, %eax # USE %ecx TO COUNT THE NUMBER OF 1'S
   movl $32, %ecx 

   count_bits_for:
      cmpl $0, %ecx 
      je count_bits_final 

      subl %ecx, %ebx 
      cmpl $0, %ebx 
      jge count_bits_for_cont # THE 2-POWER IS VALID 

      addl %ecx, %ebx 
      jmp count_bits_for_final

      count_bits_for_cont:
         incb %al

      count_bits_for_final:
         shrb $1, %cl 
         jmp count_bits_for 

   count_bits_final:
      popl %ebp
      ret 

check_case:
   pushl %ebp
   movl %esp, %ebp
   
   # 8(%ebp)  = 0/1 OF vigenereChar
   # 12(%ebp) = 0/1 OF keyChar
   
   movl 8(%ebp), %ebx 
   movl 12(%ebp), %eax

   cmpb $0, %bl
   je check_case_VX
   
   # %ebx = CONSONANT => CASE 2/3 (CV, CC)
   cmpb $0, %al
   je check_case_CV # CASE 2 (CV)
   
   # %eax = CONSONANT => CASE 3 (CC)
   addb $2, %al
   jmp check_case_final
   
   check_case_VX:
      # %ebx = VOWEL => CASE 0/1 (VV, VC)
      cmpb $0, %al
      je check_case_final
      
      # %eax = CONSONANT => CASE 1 (VC)
      jmp check_case_final
      
   check_case_CV:
      movb $2, %al
   
   check_case_final:
      popl %ebp
      ret
   
check_vowel_consonant:
   # FUNCTION THAT CHECKS IF A LETTER IS A VOWEL OR A CONSONANT
   # 8(%ebp) = LETTER
   # RETURN: 0 = VOWEL, 1 = CONSONANT
   pushl %ebp
   movl %esp, %ebp
   
   # MAKE IT UPPERCASE
   movl 8(%ebp), %edx 
   cmpb $97, %dl
   jb check_vowel_consonant_cont
   subb $32, %dl
   
   check_vowel_consonant_cont:
      cmpb $65, %dl # 'A' = 65
      je case_vowel
      cmpb $69, %dl # 'E' = 69
      je case_vowel
      cmpb $73, %dl # 'I' = 73
      je case_vowel
      cmpb $79, %dl # 'O' = 79
      je case_vowel
      cmpb $85, %dl # 'U' = 85
      je case_vowel
      
      movb $1, %al
      jmp check_vowel_consonant_final
      
   case_vowel:
      xorb %al, %al
   
   check_vowel_consonant_final:
      popl %ebp
      ret
   
print_string:
   leal string, %esi
   pushl %esi
   pushl $formatStringPrint 
   call printf 
   pushl $0
   call fflush 
   addl $12, %esp
   
exit:  
   movl $1, %eax
   xorl %ebx, %ebx 
   int $0x80
