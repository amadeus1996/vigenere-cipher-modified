# Assembly String Encryption - Vigenère Cipher (modified)

## TABLE OF CONTENTS
- [Description](#description)
- [Algorithm](#algorithm-idea)
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

A few input examples with the corresponding outputs may be found in a separate text file.

#### 3. ENCRYPTION
The first step of the algorithm is to apply the vigenère cipher.

There are a few implementation particularities: the lengths of the text and the encryption key will usually not match eachother, and there will sometimes be non-letter characters in the text. The first issue is easily resolved: if the length of the text is greater than the length of the encryption key, then keep concatenating the encryption key to itself until the lengths are matched. Otherwise, just work with the length of the text and ignore the extra key characters.

If the current character of the text is anything other than a letter, it will be skipped and the corresponding key character will be consumed.

For the input text "email@address.com" and the encryption key "flying", the key will become "flyingflyingflyin" and the resulting encrypted text will be "zuvqg@vlyzzan.xwh".

Upon completing this process, the program moves forward to the second major step of the encryption algorithm: working with vowels and consonants. The vigenère-encrypted string will be encrypted once again, applying a different method while using the same encryption key. There will be 4 cases to take into account:
- <b>CASE 0 (VV)</b>: the current text letter is a <b>vowel</b>, and the current key letter is a <b>vowel</b> (thus the abbreviation VV).
- <b>CASE 1 (VC)</b>: the current text letter is a <b>vowel</b>, and the current key letter is a <b>consonant</b>.
- <b>CASE 2 (CV)</b>: the current text letter is a <b>consonant</b>, and the current key letter is a <b>vowel</b>.
- <b>CASE 3 (CC)</b>: the current text letter is a <b>consonant</b>, and the current key letter is a <b>consonant</b>

For every case, a different approach will be taken. However, they all share some common operations as well.

In order to continue encrypting, the idea is to take the each letter of the encryption key and acquire the number of not-null bits in the 7-bit binary representation. The reason for not using 8-bit binary representations is because the MSB (2<sup>7</sup>) will always be 0 for any letter (max ASCII value for a letter is 122). The 2<sup>6</sup> bit will also always be 1 for any letter, but I decided to include it in the counter.

For the current text letter (post vigenere-encryption), once the number of not-null bits in the key letter has been acquired, an encryption mechanism will be applied depending on the case:

- <b>CASE 0 (VV)</b>: for every bit of the current text letter (starting from the 2nd MSB - 2<sup>5</sup>), XOR it with the corresponding key bit. Subtract the number of 1's (in the 7-bit binary representation of keyChar) from the resulting character.
- <b>CASE 1 (VC)</b>: subtract the number of 1's from the current text letter.
- <b>CASE 2 (CV)</b>: subtract the number of 0's from the current text letter.
- <b>CASE 3 (CC)</b>: for every bit of the current text letter (starting from the 2nd MSB - 2<sup>5</sup>), XOR it with the corresponding key bit. Subtract the number of 0's from the resulting character.

That was the final step of the encryption; all that is left is to print the string. The 2<sup>6</sup> bit is always skipped when performing XOR operations, because the text and key letters may sometimes be equal during the algorithm, so a complete XOR would result in the value 0 (and then you're supposed to subtract from 0 as well); we are out of bounds for the ASCII values of characters.

In the last 2 cases, instead of subtracting the number of 1's, the number of 0's is used instead, which is equal to 7 MINUS number of 1's.

Entering <b>0</b> will activate the encryption, and the text "<b>18-Character Text.</b>" with the encryption key "<b>dijkstra</b>" will yield the result "<b>18-dG=e=>_AG vAtO.</b>" (which can be decrypted back).

#### 4. DECRYPTION
Once again - before officially decrypting the string, the lengths of the encrypted text and the encryption key must match eachother.

First of all, a non-letter character in the encrypted string may be a letter in the decrypted string. Notice how in the encryption example provided, some of the letters turned into non-letter characters; that is the reason why the 3rd input string (the one consisting of 0's, 1's and 2's) is necessary for decrypting the text. It allows us to know which characters are actually letters, and which ones must be skipped (0=vowel, 1=consonant, 2=skip).

When looping through the characters of the text, check if the current character is a letter. If so, the algorithm continues by checking if it's a vowel or a consonant. This is because we must check the case in order to decrypt the letter (VV, VC, CV, CC), and so we must also check the state of the current key letter. Once the case has been confirmed and the number of 1-bits in the current key letter has been retrieved, we perform various decrypting operations depending on the case:

- <b>CASE 0 (VV)</b>: add the number of 1's to the current encrypted character. For every bit except the MSB (2<sup>6</sup>), find X in the following equation: X XOR currentKeyBit = currentEncryptedBit. This way, we will retrieve the binary representation for the value of the current vigenère-encrypted character.
- <b>CASE 1 (VC)</b>: add the number of 1's to the current encrypted character.
- <b>CASE 2 (CV)</b>: add the number of 0's to the current encrypted character.
- <b>CASE 3 (CC)</b>: add the number of 0's to the current encrypted character. Upon completion, continue with the same operations as in the VV case.

Once this step has been finished, it still won't grant us the original character, since the vigenère encryption has not been cracked yet; decrypting the vigenère cipher is the final stretch.

During the encryption, each character had been shifted to the <b>right</b>. Now, they will be shifted to the left by the number of positions of the corresponding key character. For example, shifting the encrypted character 'A' to the left by the number of positions of the corresponding key character 'E' will result in the letter 'W'. Performing these decryption operations for every character will fully decrypt the text.

Entering <b>1</b> will activate the decryption, and the text "<b>17vE]zeUi\[AGiNrL...</b>" with the encryption key "<b>awol</b>" and the string "<b>2211011110111111222</b>" will yield the result "<b>17isAPrimeNumber...</b>" (which may be encrypted back).

## Restrictions

- the input number should be 0 for encryption and 1 for decryption; any other value will automatically activate the encryption algorithm
- the lengths of the text to be encrypted/decrypted, the encryption key and the 0-1-2 string may not be greater than 255
- the only characters allowed in the encryption key are letters (both lowercase and uppercase)

##### LAST UPDATED 07/10/2024 (OCTOBER 7TH, 2024)
