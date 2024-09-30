# !WORK IN PROGRESS!

# Assembly String Encryption - Vigenère Cipher (modified)

## TABLE OF CONTENTS
- [Description](#description)
- [Algorithm](#algorithm-idea)
- [Data examples](#data-examples)
- [Restrictions](#restrictions)

## DESCRIPTION

This is a personal project that I made before (and during the beginning of) my 2nd year of university.

It is written in x86 Assembly (AT&T syntax). I made use of fundamental concepts and techniques, such as variables, basic operations with the registers, bit operations, conditional statements and loops, working with arrays and strings, iterative functions, function calls with arguments, working with the stack and so on.

The goal of the program is to encrypt data (strings), using an encryption algorithm called "Vigenère cipher" (with some minor tweaks), as well as adding an extra step of encryption on top of the cipher (thus the "modified" in the title).

In addition to the encryption mechanism, there is also the feature of inputting an already encrypted text and then decrypting it (the input text obviously having been encrypted using the same algorithm).

## ALGORITHM IDEA

#### 1. INTRO
Vigenère cipher is simply a more sophisticated version of the Caesar cipher. 

The idea behind Caesar cipher is to shift every single letter of the text (emphasis on the word "letter", other characters will NOT be affected by this program) by a specified amount of positions in the alphabet (with wrap-around). For example, shifting the letter 'A' two positions will result in the letter 'C', shifting 'z' two positions will result in 'b', and so on.

As for the vigenère cipher, each letter is shifted by the number of positions indicated by the corresponding key letter, in the alphabet. For example - if the current text letter is 'b' and the corresponding key letter is 'D', then the text letter will be shifted by 3 positions, since 'D' is the 4th letter of the alphabet and indexing starts from zero, resulting in 'e' (obviously it is not case-sensitive).

For the input text "string", applying the key "bridge" will result in the encrypted text "tkzltk".

#### 2. INPUT
The first part of the input consists of a number (0 or 1). Entering 0 means the program will choose to encrypt the string, while entering 1 will activate the decryption algorithm. Any other number will cancel the running of the program.

Two strings must be provided - the text to be encrypted/decrypted, as well as the encryption key.

In the case of decryption, an additional string must be provided, consisting of only the characters "0", "1" or "2". This will help determine the positions of vowels and consonants, which will be relevant for the decryption mechanism. Additional information will be provided below.

#### 3. ENCRYPTION
The first step of the algorithm is to apply the vigenère cipher.

There are a few implementation particularities: the lengths of the text and the encryption key will usually not match eachother, and there will sometimes be non-letter characters in the text. The first issue is easily resolved: if the length of the text is greater than the length of the encryption key, then keep concatenating the encryption key to itself until the lengths are matched. Otherwise, just work with the length of the text and ignore the extra key characters.

If the current character of the text is something else than a letter, it will be skipped and the corresponding key character will be consumed.

For the input text "email@address.com" and the encryption key "flying", the key will become "flyingflyingflyin" and the resulting encrypted text will be "zuvqg@vlyzzan.xwh".

Upon completing this process, the program moves forward to the second major step of the encryption algorithm: working with vowels and consonants. The vigenère-encrypted string will be encrypted once again, applying a different method while using the same encryption key. There will be 4 cases to take into account:
- CASE 0 (VV): the current text letter is a <b>vowel</b>, and the current key letter is a <b>vowel</b> (thus the abbreviation VV).
- CASE 1 (VC): the current text letter is a <b>vowel</b>, and the current key letter is a <b>consonant</b>.
- CASE 2 (CV): the current text letter is a <b>consonant</b>, and the current key letter is a <b>vowel</b>.
- CASE 3 (CC): the current text letter is a <b>consonant</b>, and the current key letter is a <b>consonant</b>

For every case, a different approach will be taken. However, they all share some common operations as well.

To continue moving forward with the algorithm, the binary representation of the encryption key is required. The idea is to take the letters of the encryption key, acquire their ASCII values and turn them into 7-bit binary representations. The reason why only 7 bits are necessary (not 8) is because the MSB (2^7) will always be 0 for any letter, so it's better to just ignore it. 

## 4. DECRYPTION

## Data examples

## Restrictions

##### LAST UPDATED 10/1/2024
