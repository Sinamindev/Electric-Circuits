;========1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
;Author information
;  Author name: Sina Amini  
;  Author email: sinamindev@gmail.com
;Project information
;  Title: Electric Circuits in Parallel
;  Purpose: To experience vector processing by using the AVX component
;  Status: No known errors
;  Files: electric-circuits-driver.cpp, electric-circuits.asm
;Module information
;  This module's call name: electric_circuits
;  Language: X86-64
;  Syntax: Intel
;  Date last modified: 2014-Sep-4
;  Purpose: This module will read and analyze the voltage and power consumption of 4 devices in a direct current circuit configured in parallel  
;  File name: electric-circuits.asm
;  Status: This module functions as expected.
;  Future enhancements: None planned
;Translator information
;  Linux: nasm -f elf64 -l electric-circuits.lis -o electric-circuits.o electric-circuits.asm
;References and credits
;  Seyfarth
;  Professor Holliday public domain programs
;Format information
;  Page width: 172 columns
;  Begin comments: 61
;  Optimal print specification: Landscape, 7 points or smaller, monospace, 8½x11 paper
;
;===== Begin code area ====================================================================================================================================================
extern printf                                               ;External C++ function for writing to standard output device

extern scanf                                                ;External C++ function for reading from the standard input device

global electric_circuits                                    ;This makes electric_circuits callable by functions outside of this file.

segment .data                                               ;Place initialized data here

;===== Declare some messages ==============================================================================================================================================

initialmessage db "This program will help analyze direct current circuits configured in parallel. ", 10, 0

promptmessage0 db "Please enter the voltage of the entire circuit in volts: ", 0

promptmessage1 db "Enter the power of 4 devices (watts) separated by space and press enter: ", 0

promptsuccess db "Thank you. The computations have completed with the following results ", 10, 10, 0

outputvoltage db "Circuit total voltage: %1.18lf ", 10, 0

outputdevicenum db "Device number       1           2           3           4 ",10, 0

outputwatts db "Power (watts): %1.18lf %1.18lf %1.18lf %1.18lf",10, 0

outputamps db "Current (amps): %1.18lf %1.18lf %1.18lf %1.18lf", 10, 10, 0

outputampstotal db "Total current in the circuits is %1.18lf amps.", 10, 0

outputwattstotal db "Total power in the circuit is %1.18lf watts.", 10,0

xsavenotsupported.notsupportedmessage db "The xsave instruction and the xrstor instruction are not supported in this microprocessor.", 10
                                      db "However, processing will continue without backing up state component data", 10, 0

goodbye db "The analyzer program will now return the total power to the driver. ",10, 10, 0

stringformat db "%s", 0                                     ;general string format

xsavenotsupported.stringformat db "%s", 0

eight_byte_format db "%lf", 0                               ;general 8-byte float format

fourfloatformat db "%lf %lf %lf %lf", 0

segment .bss                                                ;Place un-initialized data here.

align 64                                                    ;Insure that the inext data declaration starts on a 64-byte boundar.
backuparea resb 832                                         ;Create an array for backup storage having 832 bytes.

;===== Begin executable instructions here =================================================================================================================================

segment .text                                               ;Place executable instructions in this segment.

electric_circuits:                                          ;Entry point.  Execution begins here.

;=========== Back up all the GPRs whether used in this program or not =====================================================================================================

push       rbp                                              ;Save a copy of the stack base pointer
mov        rbp, rsp                                         ;We do this in order to be 100% compatible with C and C++.
push       rbx                                              ;Back up rbx
push       rcx                                              ;Back up rcx
push       rdx                                              ;Back up rdx
push       rsi                                              ;Back up rsi
push       rdi                                              ;Back up rdi
push       r8                                               ;Back up r8
push       r9                                               ;Back up r9
push       r10                                              ;Back up r10
push       r11                                              ;Back up r11
push       r12                                              ;Back up r12
push       r13                                              ;Back up r13
push       r14                                              ;Back up r14
push       r15                                              ;Back up r15
pushf                                                       ;Back up rflags

;==========================================================================================================================================================================
;===== Begin State Component Backup =======================================================================================================================================
;==========================================================================================================================================================================

;=========== Before proceeding verify that this computer supports xsave and xrstor ========================================================================================
;Bit #26 of rcx, written rcx[26], must be 1; otherwise xsave and xrstor are not supported by this computer.
;Preconditions: rax holds 1.
mov        rax, 1

;Execute the cpuid instruction
cpuid

;Postconditions: If rcx[26]==1 then xsave is supported.  If rcx[26]==0 then xsave is not supported.

;=========== Extract bit #26 and test it ==================================================================================================================================

and        rcx, 0x0000000004000000                          ;The mask 0x0000000004000000 has a 1 in position #26.  Now rcx is either all zeros or
                                                            ;has a single 1 in position #26 and zeros everywhere else.
cmp        rcx, 0                                           ;Is (rcx == 0)?
je         xsavenotsupported                                ;Skip the section that backs up state component data.

;========== Call the function to obtain the bitmap of state components ====================================================================================================

;Preconditions
mov        rax, 0x000000000000000d                          ;Place 13 in rax.  This number is provided in the Intel manual
mov        rcx, 0                                           ;0 is parameter for subfunction 0

;Call the function
cpuid                                                       ;cpuid is an essential function that returns information about the cpu

;Postconditions (There are 2 of these):

;1.  edx:eax is a bit map of state components managed by xsave.  At the time this program was written (2014 June) there were exactly 3 state components.  Therefore, bits
;    numbered 2, 1, and 0 are important for current cpu technology.
;2.  ecx holds the number of bytes required to store all the data of enabled state components. [Post condition 2 is not used in this program.]
;This program assumes that under current technology (year 2014) there are at most three state components having a maximum combined data storage requirement of 832 bytes.
;Therefore, the value in ecx will be less than or equal to 832.

;Precaution: As an insurance against a future time when there will be more than 3 state components in a processor of the X86 family the state component bitmap is masked to
;allow only 3 state components maximum.

mov        r15, 7                                           ;7 equals three 1 bits.
and        rax, r15                                         ;Bits 63-3 become zeros.
mov        r15, 0                                           ;0 equals 64 binary zeros.
and        rdx, r15                                         ;Zero out rdx.

;========== Save all the data of all three components except GPRs =========================================================================================================

;The instruction xsave will save those state components with on bits in the bitmap.  At this point edx:eax continues to hold the state component bitmap.

;Precondition: edx:eax holds the state component bit map.  This condition has been met by the two pops preceding this statement.
xsave      [backuparea]                                     ;All the data of state components managed by xsave have been written to backuparea.

push qword -1                                               ;Set a flag (-1 = true) to indicate that state component data were backed up.
jmp        startapplication

;========== Show message xsave is not supported on this platform ==========================================================================================================
xsavenotsupported:

mov        rax, 0
mov        rdi, .stringformat
mov        rsi, .notsupportedmessage                        ;"The xsave instruction is not suported in this microprocessor.
call       printf

push qword 0                                                ;Set a flag (0 = false) to indicate that state component data were not backed up.

;==========================================================================================================================================================================
;===== End of State Component Backup ======================================================================================================================================
;==========================================================================================================================================================================


;==========================================================================================================================================================================
startapplication: ;===== Begin the application here: Electric Circuits in Parallel ========================================================================================
;==========================================================================================================================================================================

;==== Show the initial message ============================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, initialmessage                              ;"This program will help analyze direct current circuits configured in parallel. "
call       printf                                           ;Call a library function to make the output

;==== Prompt for floating point number ====================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, promptmessage0                              ;"Please enter the voltage of the entire circuit in volts: "
call       printf                                           ;Call a library function to make the output

;==== Obtain a floating point number from the standard input device and store a copy in xmm10 =============================================================================
                                            
mov qword  rax, 0                                           ;SSE is not involved in this scanf operation
mov        rdi, eight_byte_format                           ;"%lf"
mov        rsi, rsp                                         ;Give scanf a point to the reserved storage
call       scanf                                            ;Call a library function to do the input work
movupd     xmm13, [rsp]
pop        rax

;==== Prompt for 4 floating point numbers =================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, promptmessage1                              ;"Enter the power of 4 devices (watts) separated by space and press enter: "
call       printf                                           ;Call a library function to make the output

;==== Scan 4 floating point numbers========================================================================================================================================
push qword 0
push qword 0
push qword 0
push qword 0
 
mov rax, 0
mov rdi, fourfloatformat
mov rsi, rsp
mov rdx, rsp
add rdx, 8
mov rcx, rsp
add rcx, 16
mov r8,  rsp
add r8,  24
call scanf
 
vmovupd ymm15, [rsp]
pop rax
pop rax
pop rax
pop rax


;==== Output the voltage with device numbers===============================================================================================================================
mov qword  rax, 0                                           ;0 floating point numbers will be outputted
mov        rdi, stringformat                                ;Prepare printf for string output
mov        rsi, promptsuccess                               ;"Thank you. The computations have completed with the following results" 
call       printf                                           ;Call a library function to do the hard work

movsd      xmm0, xmm13
mov        rax, 1                                           ;1 floating point numbers will be outputted
mov        rdi, outputvoltage                               ;"Circuit total voltage: %1.18lf"
call       printf                                           ;Call a library function to do the hard work

mov        rax, 0                                           ;0 floating point numbers will be outputted
mov        rdi, outputdevicenum                             ;"      1           2           3           4 "
call       printf                                           ;Call a library function to do the hard work



;==== Move stack into xmm registers to output watts========================================================================================================================
push qword 0
push qword 0
push qword 0
push qword 0
 

vmovupd ymm14, ymm15
vmovupd [rsp], ymm15

movsd xmm0, [rsp]
pop rax
movsd xmm1, [rsp]
pop rax
movsd xmm2, [rsp]
pop rax
movsd xmm3, [rsp]
pop rax

mov rax, 4                                                  ;4 floating point numbers will be outputted
mov rdi, outputwatts
call printf                                                 ;Call a library function to do the hard work

;==== Move voltage onto the stack four times for division  ================================================================================================================

push qword 0
push qword 0
push qword 0
push qword 0

movsd [rsp], xmm13
movsd [rsp+8], xmm13
movsd [rsp+16], xmm13
movsd [rsp+24], xmm13

vmovupd ymm13, [rsp]

vdivpd ymm14, ymm14, ymm13

;==== Move 4 float values into xmm registers for output====================================================================================================================
vmovupd [rsp], ymm14

movsd xmm0, [rsp]
pop rax
movsd xmm1, [rsp]
pop rax
movsd xmm2, [rsp]
pop rax
movsd xmm3, [rsp]
pop rax

mov rax, 4                                      ;4 floating point numbers will be outputted
mov rdi, outputamps
call printf

;==== Compute total current in the circuit ================================================================================================================================

vhaddpd ymm13, ymm14, ymm14
vextractf128 xmm12, ymm13, 1
addsd xmm12, xmm13
vmovupd ymm14, ymm12
movsd xmm0, xmm14


;==== Output the total current in entire circuit ==========================================================================================================================

mov        rax, 1                                           ;1 floating point numbers will be outputted
mov        rdi, outputampstotal                             ;"Total current in the circuits is %1.18lf amps. "
call       printf                                           ;Call a library function to do the hard work


;==== compute total power in the circuit ==================================================================================================================================
vhaddpd ymm13, ymm15, ymm15                                 ;add values within ymm15 together and store them in ymm13
vextractf128 xmm12, ymm13, 1                                ;extracts first two values from ymm13 and places them in xmm12
addsd xmm12, xmm13                                          ;adds values from xmm13 and xmm12 together and stores them into xmm12
vmovupd ymm15, ymm12
movsd xmm0, xmm15

;==== output the total power in the circuit ===============================================================================================================================

mov        rax, 1                                           ;1 floating point numbers will be outputted
mov        rdi, outputwattstotal                            ;"Total power in the circuit is %1.18lf watts. "
call       printf                                           ;Call a library function to do the hard work

;===== Conclusion message =================================================================================================================================================
push qword 0     
mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, goodbye                                     ;"The analyzer program will now return the total power to the driver."
call       printf                                           ;Call a llibrary function to do the hard work.
pop        rax 
;===== Retrieve a copy of the quotient that was backed up earlier =========================================================================================================

pop        r15                                              ;A copy of the quotient is in r14 (temporary storage)

;Now the stack is in the same state as when the application area was entered.  It is safe to leave this application area.


;==========================================================================================================================================================================
;===== Begin State Component Restore ======================================================================================================================================
;==========================================================================================================================================================================

;===== Check the flag to determine if state components were really backed up ==============================================================================================

pop        rbx                                              ;Obtain a copy of the flag that indicates state component backup or not.
cmp        rbx, 0                                           ;If there was no backup of state components then jump past the restore section.
je         setreturnvalue                                   ;Go to set up the return value.

;Continue with restoration of state components;

;Precondition: edx:eax must hold the state component bitmap.  Therefore, go get a new copy of that bitmap.

;Preconditions for obtaining the bitmap from the cpuid instruction
mov        rax, 0x000000000000000d                          ;Place 13 in rax.  This number is provided in the Intel manual
mov        rcx, 0                                           ;0 is parameter for subfunction 0

;Call the function
cpuid                                                       ;cpuid is an essential function that returns information about the cpu

;Postcondition: The bitmap in now in edx:eax

;Future insurance: Make sure the bitmap is limited to a maximum of 3 state components.
mov        r15, 7
and        rax, r15
mov        r15, 0
and        rdx, r15

xrstor     [backuparea]

;==========================================================================================================================================================================
;===== End State Component Restore ========================================================================================================================================
;==========================================================================================================================================================================


setreturnvalue: ;=========== Set the value to be returned to the caller ===================================================================================================

push       r15                                              ;r14 continues to hold the first computed floating point value.
movsd      xmm0, [rsp]                                      ;That first computed floating point value is copied to xmm0[63-0]
pop        r15                                              ;Reverse the push of two lines earlier.

;=========== Restore GPR values and return to the caller ==================================================================================================================

popf                                                        ;Restore rflags
pop        r15                                              ;Restore r15
pop        r14                                              ;Restore r14
pop        r13                                              ;Restore r13
pop        r12                                              ;Restore r12
pop        r11                                              ;Restore r11
pop        r10                                              ;Restore r10
pop        r9                                               ;Restore r9
pop        r8                                               ;Restore r8
pop        rdi                                              ;Restore rdi
pop        rsi                                              ;Restore rsi
pop        rdx                                              ;Restore rdx
pop        rcx                                              ;Restore rcx
pop        rbx                                              ;Restore rbx
pop        rbp                                              ;Restore rbp

ret                                                         ;No parameter with this instruction.  This instruction will pop 8 bytes from
                                                            ;the integer stack, and jump to the address found on the stack.
;========== End of program electric-circuits.asm ==========================================================================================================================
;========1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
