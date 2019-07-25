; Deaconu Andreea-Carina, 324CC

extern puts
extern printf
extern strlen

%define BAD_ARG_EXIT_CODE -1

section .data
filename: db "./input0.dat", 0
inputlen: dd 2263

fmtstr:            db "Key: %d",0xa, 0
usage:             db "Usage: %s <task-no> (task-no can be 1,2,3,4,5,6)", 10, 0
error_no_file:     db "Error: No input file %s", 10, 0
error_cannot_read: db "Error: Cannot read input file %s", 10, 0

section .text
global main

xor_strings:
	; TODO TASK 1
       push ebp
       mov ebp, esp

       mov eax, [ebp+8] ;encoded string
       mov ebx, [ebp+12] ;key
       
xor_one_byte:
       cmp byte [eax], 0x00
       je xor_strings_end ;s-a ajuns la sfarsit de sir
       mov dl, [eax]
       xor dl, [ebx] ;xor intre un byte din sir si unul din cheie
       mov [eax], dl ;il actualizez in sir
       inc eax ;trec la urmatorul byte
       inc ebx
       jmp xor_one_byte

xor_strings_end:
       mov esp, ebp
       pop ebp
       ret

rolling_xor:
	; TODO TASK 2
       push ebp
	mov ebp, esp

       mov eax, [ebp+8] ;encoded string
       ;primul byte din sir nu se schimba la criptare, trec la al doilea
       inc eax
       
rolling_xor_one_byte:
       cmp byte [eax], 0x00
       je rolling_xor_end ;am ajuns la sfarsit de sir
       mov ebx, [ebp+8] ;iau inceputul sirului in ebx
       
xor_until_current:
       cmp eax, ebx
       je done_one_byte ;daca s-a ajuns la byte-ul curent
       mov dl, [ebx]
       xor [eax], dl ;fac xor cu cate un byte de dinainte
       inc ebx ;trec la urmatorul byte pt a face xor cu el
       jmp xor_until_current
   
done_one_byte:    
       inc eax ;trec la urmatorul byte de decriptat
       jmp rolling_xor_one_byte

rolling_xor_end:
       mov esp, ebp
       pop ebp
       ret

hex_char_to_bin:
       push ebp
       mov ebp, esp

       mov ecx, [ebp+8] ;un caracter hexazecimal
       cmp byte cl, 'a'
       jge letter ;daca e litera, ii aflu valoarea(10, 11,... 15)
       sub byte cl, '0'
       jmp replace
       
letter:
       sub byte cl, 'a'
       add byte cl, 10 
       
replace:
       mov [ebp+8], ecx ;actualizez caracterul
       mov esp, ebp
       pop ebp
       ret
     
hex_string_to_bin:
       push ebp
       mov ebp, esp

       mov eax, [ebp+8] ;hex string
       ;iau cate 2 caractere odata
       ;deci, noul sir va avea o lungime diferita
       xor ebx, ebx ;ebx va retine pozitia unde am ajuns in modificarea lui
       
form_one_byte:
       cmp byte [eax], 0x00 
       je hex_string_to_bin_end ;sfarsit de sir
       xor edx, edx
       mov byte dl, [eax]
       push edx
       call hex_char_to_bin ;convertesc un caracter in binar
       pop edx
       imul edx, 16 ;il inmultesc cu 16
       mov [eax], dl ;il actualizez in sir
       xor edx, edx
       mov dl, [eax+1] ;il iau pe urmatorul
       push edx
       call hex_char_to_bin ;il convertesc
       pop edx 
       add [eax], dl ;il adun
       mov dl, [eax]
       mov [eax+ebx], dl ;pun octetul nou format in rand cu ceilalti
       dec ebx ;ebx e negativ, deci il decrementez ca sa-i cresc modulul
       add eax, 2 ;trec la urmatoarele 2 caractere
       jmp form_one_byte
       
hex_string_to_bin_end:     
       mov byte [eax+ebx], 0x00 ;adaug null pentru a delimita noul sir format
       
       mov esp, ebp
       pop ebp
       ret
       
xor_hex_strings:
	; TODO TASK 3
       push ebp
       mov ebp, esp

       mov eax, [ebp+8] ;encoded string
       push eax
       call hex_string_to_bin ;o convertesc in binar
       add esp, 4
       
       mov ebx, [ebp+12] ;key
       push ebx
       call hex_string_to_bin ;o convertesc in binar
       add esp, 4
       
       mov eax, [ebp+8] ;encoded string
       mov ebx, [ebp+12] ;key
       push ebx
       push eax
       call xor_strings ;functia de la task-ul 1
       add esp, 8
       
       mov esp, ebp
       pop ebp
       ret

base32decode:
       ; TODO TASK 4
       push ebp
       mov ebp, esp
       
       mov eax, [ebp+8] ;encoded string
       
go_to_end: ;vreau sa ajung la ultimul caracter alfabetic din sir
       cmp byte [eax], '='
       je found_end
       cmp byte [eax], 0x00
       je found_end
       inc eax ;trec la urmatorul
       jmp go_to_end
      
found_end: ;am ajuns pe primul caracter de tip '=' sau 0x00
       dec eax ;ma duc inapoi cu un caracter
       
       push 2 ;pun valoarea 2 ca sa stiu unde ma voi opri
   
push_group_of_5:
       cmp eax, [ebp+8] ;daca am parcurs tot sirul
       jl take_byte_from_stack
       cmp byte [eax], 'A'
       jl not_letter
       sub byte [eax], 'A' ;pentru litere ma raportez la 'A'
       jmp start_pushing_bits
       
not_letter:
       sub byte [eax], 24 ;pentru cifre trebuie sa scad 24 din codul ASCII
       
start_pushing_bits:
       mov ecx, 5 ;voi pune (ultimii) 5 biti din octet pe stiva

push_bit_on_stack:
       shr byte [eax], 1 ;iau cate un bit 
       jc push_1 ;bitul este 1
       jmp push_0 ;bitul este 0
       
push_1:
       push 1
       loop push_bit_on_stack
       jmp next_5
        
push_0:
       push 0
       loop push_bit_on_stack
  
next_5:     
       dec eax ;ma mut un caracter la stanga
       jmp push_group_of_5  

take_byte_from_stack:
       inc eax 
       mov ecx, 8 ;voi lua 8 biti de pe stiva (cat pentru un octet)
       
take_bit_from_stack:
       pop edx
       cmp edx, 2 
       je base32decode_end ;am terminat de luat de pe stiva
       shl byte [eax], 1 ;inmultesc numarul curent cu 2
       add [eax], edx ;si adaug un nou bit
       loop take_bit_from_stack 
       jmp take_byte_from_stack
             
base32decode_end:      
       mov esp, ebp
       pop ebp
       ret

bruteforce_singlebyte_xor:
       ; TODO TASK 5
       push ebp
       mov ebp, esp 
        
       xor ecx, ecx ;ecx e cheia, incep cu valoarea 0
       
try_one_key:
       mov eax, [ebp+8] ;encoded string
       
search_for_f:
       mov byte bl, [eax]
       cmp bl, 0x00
       je change_key
       xor bl, cl
       cmp bl, 'f' ;caut litera 'f'
       je search_for_o ;daca o gasesc, voi cauta 'o'
       inc eax ;nu am gasit 'f', trec la urmatorul caracter
       jmp search_for_f
       
search_for_o:
       inc eax
       mov byte bl, [eax]
       cmp bl, 0x00
       je change_key
       xor bl, cl
       cmp bl, 'o' 
       je search_for_r ;daca am gasit si 'o', caut 'r'
       inc eax
       jmp search_for_f ;daca nu, caut iar 'f'
       
search_for_r:
       inc eax
       mov byte bl, [eax]
       cmp bl, 0x00
       je change_key
       xor bl, cl
       cmp bl, 'r'
       je search_for_c ;daca am gasit si 'r', caut 'c'
       inc eax
       jmp search_for_f ;daca nu, caut iar 'f'
       
search_for_c:
       inc eax
       mov byte bl, [eax]
       cmp bl, 0x00
       je change_key
       xor bl, cl
       cmp bl, 'c'
       je search_for_e ;daca am gasit si 'c', caut 'e'
       inc eax
       jmp search_for_f ;daca nu, caut iar 'f'
       
search_for_e:
       inc eax
       mov byte bl, [eax]
       cmp bl, 0x00
       je change_key
       xor bl, cl
       cmp bl, 'e' ;daca am gasit si 'e', cheia e cea buna
       je found_key
       inc eax
       jmp search_for_f ;daca nu, caut iar 'f' 
       
change_key:
       inc ecx
       jmp try_one_key
       
found_key:    
       mov eax, ecx ;returnez valoarea cheii in eax
       mov ebx, [ebp+8] ;encoded string
       
singlebyte_xor:
       cmp byte [ebx], 0x00
       je bruteforce_singlebyte_xor_end ;am ajuns la sfarsit de sir
       xor byte [ebx], al ;fac xor intre un byte din sir si cheie
       inc ebx ;trec la urmatorul byte
       jmp singlebyte_xor
       
bruteforce_singlebyte_xor_end:
       mov esp, ebp
       pop ebp
       ret

decode_vigenere:
       ; TODO TASK 6
       push ebp
       mov ebp, esp

       mov eax, [ebp+8] ;encoded string

get_key:
       mov ecx, [ebp+12] ;key
       
rot_one_byte:
       cmp byte [eax], 0x00
       je decode_vigenere_end ;am ajuns la sfarsit de sir
       cmp byte [eax], 'a'
       jl continue ;caracterul nu este litera
       cmp byte [eax], 'z'
       jg continue ;caracterul nu este litera
       mov byte dl, [ecx] ;iau o litera din cheie
       sub dl, 'a' ;aflu offset-ul ei fata de 'a'
       sub byte [eax], dl ;rotesc la stanga caracterul respectiv din sir
       cmp byte [eax], 'a' ;daca a depasit (s-a dus mai la stanga de 'a')
       jge increment_key
       ;aflu cu cat s-a depasit 'a' - [eax]
       ;ma deplasez de la 'z' in stanga ('z' - ('a' - [eax]) )
       ;apoi trebuie sa ma mai duc la dreapta cu 1
       ;aceste operatii sunt echivalente cu instructiunile:
       add byte [eax], 'z'
       sub byte [eax], 'a'
       add byte [eax], 1
       
increment_key:
       inc ecx ;trec la urmatorul caracter
       inc eax ;trec la urmatorul caracter
       cmp byte [ecx], 0x00
       je get_key ;am ajuns la sfarsitul cheii, o iau de la inceput
       jmp rot_one_byte
       
continue:
       inc eax ;trec la urmatorul caracter
       jmp rot_one_byte
       
decode_vigenere_end:
       mov ebp, esp
       pop ebp
       ret

main:
	push ebp
	mov ebp, esp
	sub esp, 2300

	; test argc
	mov eax, [ebp + 8]
	cmp eax, 2
	jne exit_bad_arg

	; get task no
	mov ebx, [ebp + 12]
	mov eax, [ebx + 4]
	xor ebx, ebx
	mov bl, [eax]
	sub ebx, '0'
	push ebx

	; verify if task no is in range
	cmp ebx, 1
	jb exit_bad_arg
	cmp ebx, 6
	ja exit_bad_arg

	; create the filename
	lea ecx, [filename + 7]
	add bl, '0'
	mov byte [ecx], bl

	; fd = open("./input{i}.dat", O_RDONLY):
	mov eax, 5
	mov ebx, filename
	xor ecx, ecx
	xor edx, edx
	int 0x80
	cmp eax, 0
	jl exit_no_input

	; read(fd, ebp - 2300, inputlen):
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80
	cmp eax, 0
	jl exit_cannot_read

	; close(fd):
	mov eax, 6
	int 0x80

	; all input{i}.dat contents are now in ecx (address on stack)
	pop eax
	cmp eax, 1
	je task1
	cmp eax, 2
	je task2
	cmp eax, 3
	je task3
	cmp eax, 4
	je task4
	cmp eax, 5
	je task5
	cmp eax, 6
	je task6
	jmp task_done

task1:
	; TASK 1: Simple XOR between two byte streams

	; TODO TASK 1: find the address for the string and the key
        push ecx
	call strlen 
	pop ecx
        ;in eax se afla acum lungimea lui encoded_string
	add eax, ecx ;ma deplasez de la inceputul lui encoded_string pana la sfarsitul sau
	inc eax
        ;acum, eax se afla la inceputul lui key
       
	; TODO TASK 1: call the xor_strings function
        push eax
        push ecx
        call xor_strings
        pop ecx ;iau sirul modificat in ecx
        add esp, 4 ;restaurez stiva
       
	push ecx
	call puts                   ;print resulting string
	add esp, 4

	jmp task_done

task2:
	; TASK 2: Rolling XOR

	; TODO TASK 2: call the rolling_xor function
        push ecx
        call rolling_xor
        pop ecx
       
	push ecx
	call puts
	add esp, 4

	jmp task_done

task3:
	; TASK 3: XORing strings represented as hex strings

	; TODO TASK 3: find the addresses of both strings
        push ecx
	call strlen
	pop ecx

	add eax, ecx
	inc eax

	; TODO TASK 3: call the xor_hex_strings function
        push eax
        push ecx
        call xor_hex_strings
        pop ecx
        add esp, 4

	push ecx                     ;print resulting string
	call puts
	add esp, 4

	jmp task_done

task4:
	; TASK 4: decoding a base32-encoded string

	; TODO TASK 4: call the base32decode function
	push ecx
        call base32decode
        pop ecx
       
	push ecx
	call puts                    ;print resulting string
	pop ecx
	
	jmp task_done

task5:
	; TASK 5: Find the single-byte key used in a XOR encoding

	; TODO TASK 5: call the bruteforce_singlebyte_xor function
        push ecx
        call bruteforce_singlebyte_xor
        pop ecx
            
        push eax ;eax = key value, o pun pe stiva pentru apelul lui printf
	
        push ecx                    ;print resulting string
	call puts
	pop ecx
    
	push fmtstr
	call printf                 ;print key value
	add esp, 8

	jmp task_done

task6:
	; TASK 6: decode Vignere cipher

	; TODO TASK 6: find the addresses for the input string and key
        push ecx
	call strlen
	pop ecx

	add eax, ecx
	inc eax
	; TODO TASK 6: call the decode_vigenere function

	push eax
	push ecx                   ;ecx = address of input string 
	call decode_vigenere
	pop ecx
	add esp, 4
       
	push ecx
	call puts
	add esp, 4

task_done:
	xor eax, eax
	jmp exit

exit_bad_arg:
	mov ebx, [ebp + 12]
	mov ecx , [ebx]
	push ecx
	push usage
	call printf
	add esp, 8
	jmp exit

exit_no_input:
	push filename
	push error_no_file
	call printf
	add esp, 8
	jmp exit

exit_cannot_read:
	push filename
	push error_cannot_read
	call printf
	add esp, 8
	jmp exit

exit:
	mov esp, ebp
	pop ebp
	ret
