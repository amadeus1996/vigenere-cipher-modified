.section .note.GNU-stack, "", %progbits

.data
   string: .space 64
   key: .space 64
   n: .space 4
   m: .space 4
   vowels: .space 6
   formatString1: .asciz "%s"
   formatString2: .asciz "%[^\n]"
   formatStringPrint: .asciz "%s\n"
   formatInt: .asciz "%d "
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
      jne add_chars_cont
      xorl %ecx, %ecx
      jmp add_chars_cont
         
      add_chars_cont:
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
   je afisare
   
   # CHECK IF IT'S A LETTER (IF NOT, DON'T ENCRYPT)
   movb (%esi, %ecx, 1), %al 
   cmpl $65, %eax
   jb vigenere_cont
   cmpl $122, %eax
   ja vigenere_cont
   
   # SOME COMMON OPERATIONS. CHECK IF THE CURRENT CHAR OF THE KEY
   # IS A LOWERCASE OR UPPERCASE
   movb (%edi, %ecx, 1), %bl
   xorl %edx, %edx
   subl $65, %ebx
   cmpl $31, %ebx
   jbe vigenere_cont_1
   subl $32, %ebx
   
   vigenere_cont_1:
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
      jmp vigenere_cont

   vigenere_uppercase:
      subl $65, %eax
      addl %ebx, %eax
      movl $26, %ebx
      divl %ebx
      addl $65, %edx
      movl %edx, %eax
   
   vigenere_cont:
      movb %al, (%esi, %ecx, 1)
      incl %ecx
      jmp vigenere
   
afisare:
   pushl $string
   pushl $formatString1
   call printf
   pushl $0
   call fflush
   addl $12, %esp
   jmp exit
   
exit:   
   movl $1, %eax
   movl $0, %ebx
   int $0x80
