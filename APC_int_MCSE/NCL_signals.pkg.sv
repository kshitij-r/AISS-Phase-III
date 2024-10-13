// dual_rail_logic type definition
`ifndef NCL_SIG
	`define NCL_SIG
	
	package NCL_signals;
	
		typedef struct packed{
			logic rail1;
			logic rail0;
		}dual_rail_logic;
		
		typedef struct packed{
			logic rail2;
			logic rail1;
			logic rail0;
		}three_rail_logic;			

		typedef struct packed{
			logic rail3;		
			logic rail2;
			logic rail1;
			logic rail0;
		}quad_rail_logic;			
	endpackage
	
	import NCL_signals::*; // inport package into $unit
`endif