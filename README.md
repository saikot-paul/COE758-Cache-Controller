# Cache Controller Project 

If you are reading this, you are either a recruiter (please hire me) or a student who needs "help" with the first design project of COE758. Outlined below is a description of the code what it does, how it works and some other things. 

## State Diagram 

<img width="361" alt="image" src="https://github.com/saikot-paul/coe758/assets/79386282/aa0dea9f-1bd4-4b0c-94d8-8723748b4272">
## Block Diagram 

graph TD
    CLK[CLK] -->|CLK| CACHE_CONTROLLER
    ICON[ICON] -->|CONTROL0(35:0)| CACHE_CONTROLLER
    ICON -->|CONTROL1(35:0)| SD_RAM_CONTROLLER
    ILA[ILA] -->|TRIG_OUT(0)| CACHE_CONTROLLER
    CACHE_CONTROLLER -->|READY| ILA
    VIO[VIO] -->|CONTROL(255:0)| CACHE_CONTROLLER
    VIO -->|ASYNC_OUT(255:0)| CACHE_CONTROLLER
    CACHE_CONTROLLER -->|CS| SD_RAM_CONTROLLER
    CACHE_CONTROLLER -->|WEA| SD_RAM_CONTROLLER
    CACHE_CONTROLLER -->|MEM_STROBE| SD_RAM_CONTROLLER
    CACHE_CONTROLLER -->|MEM_WE| SD_RAM_CONTROLLER
    CACHE_CONTROLLER -->|MEM_ADD_OUT(11:0)| SD_RAM_CONTROLLER
    CACHE_CONTROLLER -->|MEM_DIN(7:0)| SD_RAM_CONTROLLER
    CACHE_CONTROLLER(CLK, CS, WEA, MEM_STROBE, MEM_WE, MEM_ADD_OUT, MEM_DIN, DOUT) -.-> SD_RAM_CONTROLLER
    SD_RAM_CONTROLLER -->|DOUT(7:0)| CACHE_CONTROLLER

    classDef block fill:#fff,stroke:#000,stroke-width:2px;
    class CLK,ICON,ILA,VIO,CACHE_CONTROLLER,SD_RAM_CONTROLLER block;

### States 

1) State 0 - IDLE 
    - This is the idle state, you are just waiting for the CPU to assert chip select to 1
    - Once it receives chip signal assertion then it moves to the dispatcher state 
2) State 1 - Dispatcher
    -  Depending on what the CPU wants to do you go to the corresponding state, which are the following states below
        - Read hit
        - Write hit
        - Miss d-bit = 0
        - Miss d-bit = 1
    - You may be wondering why there's not read miss, or write miss that's because you have to do block replacement when its a miss for either then perform the action required by the CPU
    - So again depending some conditions you go into that state
3) State 2 - Read Hit
      - If you get to this state, that means that the data requested to read is in the cache, so you just retrieve whatever was in the cache (BRAM) and then send it out onto the appropriate signal
      - Return to idle state
4) State 3 - Write Hit
      - If you get to this state, that means that the tag exists in the cache and now you write to the cache and set the d-bit to 1
      - Return to idle state
5) State 4 - Write Main to Cache
      - The tag was not in cache and the d-bit = 0, so you can simply perform block replacement
      - Go back to State 2 (Dispatcher) and perform actions specified by CPU 
6) State 5 - Write Cache to Main
      - The d-bit = 1, meaning that cache has been written into and therefore you need to propagate those changes to Main Memory
      - Go to State 4, once you're done

## Implementation Details 

### Design specifications
  - CPU
    - We decided to implement the CPU using VIO
    - We control the CPU signals using various input/output signals specified in the code
    - The vio signal has 4 components
      - Address : 12 bits
        - 4 bits tag
        - 3 bits index
        - 5 bits block offset  
      - CPU Data out (data you want to write) : 8 bits 
      - Chip Select: 1 bit
      - CPU Read/Write : 1 bit
  - Cache Memory 
    - Cache controller is a BRAM module
    - Address, Data in, Data out are all 8 bits
      - 3 bit index
      - 5 bits block offset
  - Main Memory 
    - Main memory is a BRAM module
    - Address is 12 bits
      - 4 bits tag    
      - 3 bit index
      - 5 bits block offset
  - Cache Memory = (8 x 32) x 1B = 256B
  - Main Memory = (2^12) x 1B = 4096B
  - You may ask why did we change the specifications from the project manual, well that's because the design specifications don't fit on the board so we made it smaller such that the main and cache memory can both fit on the board 

### Functions

Some key things to not before I start explaining the code, VHDL is a language that is literally describing the hardware. When you write code in VHDL it gets broken down to logic gates and then it loads the logic you wrote onto the FPGA. So knowing this, it means that all the processes are ran concurrently and they are "triggered" when something changes in the sensitivity list. 

1) Hit or Miss function
      - Probably the coolest thing imo
      - This is a combinational circuit it evaluates anytime an address is placed and then determines whether a hit or miss occurs by looking at the various registers
      - This determines the hit or miss signal that is used to go into the correct state
      - You are always evaluating whether there is a hit or miss, and therefore its ready for whenever a new operation is needed to be performed 
2) Update State
      - Updates the state
      - Clocked process
3) Finite State Machine
      - This determines the next state given the current state
4) Generate Outputs
      - Based on the state determine the correct outputs
      - State 0
        - Idle State so make cpu ready 0 to signify the cache is not available
      - State 1
        - Dispatcher state reset the flags for transitioning and read/write signals
      - State 2
        - Read hit state
        - Set the signals to read from cache
        - Place data read from cache onto the CPU data in bus
      - State 3
        - Write hit state
        - Set the signals to write to cache
        - Place CPU data out onto the cache data in signal
      - State 4
        - Write main to cache since d-bit = 0
        - Initialize the signals for offset, read from main memory, write to cache
        - Oscillatte mem strobe
        - Do until block is completely replaced
      - State 5
        - Write cache to main since d-bit = 1
        - Initialize signals for offset, read from cache, write to main
        - Oscillate mem strobe
        - Do until block is written to main

### Future Modifications 

#### Modularization/Refactoring

Semester around midterms was getting kind of tough so I got lazy and wrote 300+ LOC in one file so modularization would be the first thing I would do. 

1) FSM
   - The FSM would be its own module, where the processes related to the FSM: fsm, update_state, gen_outputs would be inside that module
   - It would take the CPU signals and clock as inputs and output the addresses, data in/out, read/write signals
3) Hit or miss
   - Hit or miss function could be its own block
   - This would keep track of the tags, valid, dirty bits as well
4) Top level entity
   - In this entity you would have the FSM, Hit or miss, ILA, ICON, VIO, cache memory and main memory modules

That's how I would refactor the code. 

### Other things to note 

I didn't use functional simulation for this but chipscope, so know how to use ILA, ICON and VIO, if you want to use timing then you're on your own lol. Aside from that good luck below are some pictures of chipscope simulations

#### Write Miss 
![write_miss_dbit1](https://github.com/saikot-paul/COE758-Cache-Controller/assets/79386282/a1d76e08-13f3-40ca-96a1-6169f19eb474)

#### Read Hit 
![read_hit_dbit0](https://github.com/saikot-paul/COE758-Cache-Controller/assets/79386282/944c0a99-f91f-4ccc-bdef-a79c0c01dff5)
