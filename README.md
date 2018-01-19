# SimplifiedCPU
Short and sweet CPU written in Verilog with 4kb on-chip memory, written for NC State University 

## Features
1. 4KB on-chip memory, written into simulator from ram/memory_proj.list
2. Emulation of: 
  - Datapath
  - RAM 
    - 256x16 bit input
  - ALU
    - ADD, SUB, OR, AND functions
  - Controller
    - Opcodes: ADD, OR,  SUB, AND, JMP, JMPZ, LOAD, STORE, HALT
  - Register bank:
    - PC, IR, ACC, MDR, MAR, ZFLAG
3. Generic portability: written for ModelSim, but maintains most rules regarding FPGA design tools
4. Additional testbench for sample execution for most modules

## Known Bugs
Only one bug truly exists within the CPU: when completing a store, the ACC is written to both the memory location specified as well as the _current_ PC value. Further testing is necessary. 
