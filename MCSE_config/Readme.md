# University of Florida Design-Time Configuration Automation Tool for Minimally Configured Security Engine (MCSE)



# Current State of Development
The current release of the tool supports automatic generation of MCSE instances for following configurability features
- Supports user-defined PUF sizes ranging from 256 bits
- Supports inclusion of 13 different IPs from Host
- Supports user-defined scan protection key width ranging from 16 bits
- Supports user-defined Ownership Authentication Key/Lifecycle Authentication Key sizes ranging from 256 bits
- Supports user-defined Lifecycle Transition Key sizes ranging from 256 bits
-Supports user-defined encryption function; currently supports APC and Camellia256

# Relevant Source Code Structure
- "mcse_config.json" is the script for user-defined inputs
- "mcse_configuration.py" is the configurator script for automatic generation of MCSE instances

# Tool Requirements
- Synopsys VCS 


# Automation Tool Simulation Work-flow
```````
 Modiify "mcse_config.json" with preferred input

```````
make clean

```````
make MCSEtest

<!-- Some important notes on Firmware Authentication Module -->
- If you want to generate an MCSE instance with firmware authentication module, make sure to put "puf_size >= 256". This is because I kept bus translation logic same for ipid extraction and firmware image extraction. And this tool only supports firmware blocks in 256 bits chunks so far.
-If you don't want to include firmware module, don't need to worry about anything. You can put puf size of your desire (ranging from 128 bits).

<!-- Asset Ranges -->
- In baseline MCSE security, all assets are considered to have a minimum size of 256bits with flexible upper limit
- "lifecycle_authentication_key" has to be >= 256 bits because "lifecycle_authentication_key" and "ChipID" both are stored in the same memory and memory size is defined by the size of "lifecycle_authentication_key" to avoid complexity. This is not a functional limitation of MCSE
-Maximum #16 IPIDs are supported [0-15]

***While running the configurator without firmware authentication, make sure to comment out fw related task from the testbench "mcse_top_tb.sv"