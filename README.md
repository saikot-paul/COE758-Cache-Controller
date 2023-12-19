#Cache Controller Project 

If you are reading this, you are either a recruiter (please hire me) or a student who needs "help" with the first design project of COE758. Outlined below is a description of the code what it does, how it works and some other things. 

## State Diagram 

<img width="361" alt="image" src="https://github.com/saikot-paul/coe758/assets/79386282/aa0dea9f-1bd4-4b0c-94d8-8723748b4272">

###States 

1) State 0 - IDLE 
  - This is the idle state, you are just waiting for the CPU to assert chip select to 1
  - Once it receives chip signal assertion then it moves to the dispatcher state 
2) State 1 - Dispatcher
  - Depending on what the CPU wants to do you go to the corresponding state, which are the following states below
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
  - If you get to this state, that means that the tag exists in the cache and now you write to the cache and set the dbit to 1
  - - Return to idle state
5) State 4 - Write Main to Cache
  - The tag was not in cache and the d-bit = 0, so you can simply perform block replacement
  - Go back to State 2 (Dispatcher) and perform actions specified by CPU 
6) State 5 - Write Cache to Main
  - The dbit = 1, meaning that cache has been written into and therefore you need to propagate those changes to Main Memory
  - Go to State 4, once you're done

##Implementation Details 

1) Design specifications
  - CPU
    - We decided to implement the CPU using VIO
    - We control the CPU signals using various input/output signals specified in the code
    - The vio signal has 4 components
      - Address : 12 bits
      - CPU Data out (data you want to write) : 8 bits 
      - Chip Select: 1 bit
      - CPU Read/Write : 1 bit
  - Cache Memory 
    - Cache controller is a BRAM module
    - Address, Data in, Data out are all 8 bits
    -  
3) 
4) 
