# NOC-as-a-Bus-Master-handles-CRC-as-a-Slave
Design and implementation of Master/Slave system which also includes interface/bus.    
Design of NoC Bus with additional ability to work as a Bus Master which uses both NOC & CRC interface to accomplish goal of two way handshake mechanism for handling CRC block (i.e. slave device).  
Increases efficiency of CRC interface because of addition of master device on bus.   
To do this project,   
Tools: Synopsys VCS, Design Compiler, Design Vision, or any EDA tools.  
Language: SystemVerilog   

Files,  
Top module: tbbm.sv     
NOC interface: nocif.sv    
CRC interface: crcif.sv     
NOC Design module: noc.sv     
CRC design module: crc.sv     
Bus Master Design module: bm.sv     
Simulation script: ./sv_uvm tbbm.sv     
Synthesis script: ./sss & synthesis.script     
Simulation result: finalresult_bm.txt     
Synthesis result: synres.txt     

All done with a smile... :) :) 




