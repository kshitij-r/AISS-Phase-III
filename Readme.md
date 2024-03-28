**MCSE Architecture**

- MCSE Top  
  - Minimum Security Module  
    - SHA256  
    - CAM256  
    - GPIO  
    - PCM
  - MCSE Control Unit
    - Life-cycle Protection Module
    - Secure Memory
    - Secure Boot Control 

**MCSE/TA2 GPIO Pin Out**

| Pin | Direction | Functionality | Pin | Direction | Functionality |
|:--- | :---      |  :---         |:--- | :---      |  :---         | 
| 0   | Output    | Reset HOST Soc| 1   | Input     | HOST Reset ACK| 
| 2   | Output    | Halt HOST SoC | 3   | Input     | HOST Halt ACK | 
| 4   | Output    | Normal Operation Release to Host SoC | 5 | Input | Host Normal Operation ACK |
| 6   | Output    | HOST Bus Wakeup | 7 | Input | HOST Bus Wakeup ACK | 
|8    | Output    | IPID Address[0] |    |      |                     |
|9    | Output    | IPID Address[1] |    |      |                     |
|10   | Output    | IPID Address[2] |    |      |                     |
|11   | Output    | IPID Address[3] |    |      |                     |
|12   | Output    | IPID Trigger    |    |      |                     |
|     |           |                 |13  |Input | IPID Valid          | 
| 15  | Output    | FW AUth ACK     |14  |Input | FW Image Authentication Request | 
|     |           |                 |16  |Input | IPID In[0]          | 
|     |           |                 | ↓  | ↓    |      ↓              | 
|     |           |                 |31  |Input | IPID In[15]         |

**High-Level MCSE Life-cycle Functionality**

Bullet points with an * are only completed at the first boot of each life-cycle. 

- Manufacture & Test
  - MCSE Initialization
  - Reset HOST Soc 
  - Golden ChipID Generation *
    - MCSE ID generation  
    - HOST bus wakeup
    - IP ID Extraction
    - Composite IP ID Generation
    - Golden Chip ID Generation
    - Store Golden Chip ID in memory
  - Update lifecycle
    - Transition lifecycle with life-cycle transition key (specific to each life-cycle)  
    - Reboot SoC
- Packaging & OEM
  - MCSE Initialization
  - Reset HOST Soc
  - Lifecycle Authentication (Authenticate current owner key, specific to each life-cycle) * 
  - Challenge Chip ID generation *
    - Generate Chip 
    - Fetch Golden Chip ID
    - Compare ChipID with Golden Chip ID
  - Normal operation release to HOST SoC
  - Firmware authentication (Work in progress)
  - Update lifecycle
    - Transition lifecycle with life-cycle transition key 
    - Reboot SoC
 - Deployment
   - MCSE Initialization
   - Reset HOST Soc
   - Lifecycle Authentication * 
   - Challenge Chip ID generation *
     - Generate Chip ID 
     - Fetch Golden Chip ID
     - Compare ChipID with Golden Chip ID
   - Normal operation release to HOST SoC
   - Update lifecycle
     - Transition lifecycle with life-cycle transition key 
     - Reboot SoC
 - Recall
   - MCSE Initialization
   - Reset HOST Soc
   - Lifecycle Authentication * 
   - Challenge Chip ID generation *
     - Generate Chip ID 
     - Fetch Golden Chip ID
     - Compare ChipID with Golden Chip ID
   - Normal operation release to HOST SoC
   - Update lifecycle
     - Transition lifecycle with life-cycle transition key 
     - Reboot SoC
 - End-of-Life
   - MCSE Initialization
   - Lifecycle Authentication *
   - Truncated boot sequence loop

**Simulation & Synthesis**

Through the Makefile we are executing testbenches in VCS. 

The pre-synthesis testbench is "mcse_top_tb.sv". To run it use the command (currently has to be run in the source_RTL directory but will be fixed) 

 - make MCSEtest

For synthesis using Synopsys DC, the compiledc.tcl file is used and will also produce the gate-level netlist file "mcse_netlist.v". Run the command

 - dc_shell -f compiledc.tcl

For a gate-level netlist simulation, the testbench is "mcse_top_netlist_tb.sv". Run the command

 - make NETLISTtest



