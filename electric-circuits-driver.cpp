//=======1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
//Author information
//  Author name: Sina Amini
//  Author email: sinamindev@gmail.com
//  Author location: CSUF
//Project information
//  Project title: Electric Circuits in Parallel
//  Purpose: Compute the power and current of a circuit after user inputs voltage and power consumption of 4 devices in volts
//  Status: Performs correctly on Linux 64-bit platforms with AVX
//  Project files: Project files: electric-circuits-driver.cpp, electric-circuits.asm
//Module information
//  This module's call name: circuits-in-parallel.out  This module is invoked by the user
//  Language: C++
//  Date last modified: 2014-Sep-4
//  Purpose: This module is the top level driver: it will call electric_circuits
//  File name: electric-circuits-driver.cpp
//  Status: In production.  No known errors.
//  Future enhancements: None planned
//Translator information
//  Gnu compiler: g++ -c -m64 -Wall -l electric-circuits.lis -o electric-circuits-driver.o electric-circuits-driver.cpp
//  Gnu linker:   g++ -m64 -o circuits-in-parallel.out electric-circuits-driver.o electric-circuits.o 
//References and credits
//  Seyfarth
//  Professor Holliday public domain programs 
//  This module is standard C++
//Format information
//  Page width: 172 columns
//  Begin comments: 61
//  Optimal print specification: Landscape, 7 points or smaller, monospace, 8½x11 paper
//
//===== Begin code area ===================================================================================================================================================

#include <stdio.h>
#include <stdint.h>
#include <ctime>
#include <cstring>

extern "C" double electric_circuits();

int main(){

  double return_code = -99.99;

  printf("%s","Welcome to Electric Circuit Processing by Sina Amini. \n");
  return_code = electric_circuits();
  printf("%s%1.18lf%s\n","The driver received this number: ",return_code, ".  The driver will now return 0 to the operating system.  Have a nice day.");

  return 0;

}//End of main

//===== End of main =======================================================================================================================================================
