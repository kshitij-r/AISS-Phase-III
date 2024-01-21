module pcm (clk,
			rst,
            sig_in,
            sig_valid,
            IP_ID_in,
            Instruction_in,
			control_out,
			status,
			comp_out,
            S_c,
            A_c
    );


	//INSTRUCTIONS
	`define	IDLE_IN	    3'd0
	`define	GEN_CHNG	3'd1
	`define	COMPARE	    3'd2
	`define	PROV_ID	    3'd3
	`define	PROV_EXP	3'd4
	`define	STR_CHNG	3'd5

	//STATUS 
	`define	IDLE	32'd0
	`define	COMP_NOT_VALID	32'd1
	`define	IP_ID_NOT_FOUND	32'd2
	`define	IP_PRESENT	32'd3
	`define	CHNG_NOT_VALID	32'd4

	
	parameter IP_COUNT  = 16; //max number of IP's in the systems. Also determined max number of IP addresses and comparisons that can be done. 
							//Used to set size of PUF sig input registers
							//each IP sends a 32 bit sig

    parameter data_width = 32;
    parameter addr_width = 32;
    parameter puf_sig_length = 256;
	parameter valid_byte_offset = 16;
	parameter parity_bits_width = 48;
	
    //i/o ports
    input clk, rst;
    input [puf_sig_length-1 : 0] sig_in;
    input [data_width-1 : 0] IP_ID_in;
	input [2:0] Instruction_in;
	input sig_valid;
	reg [31 : 0] Instruction_reg;
	
    output reg [data_width-1 : 0] control_out ;
	output reg [data_width-1 : 0] status ;
    
    output reg comp_out ;
    output reg S_c ; //storage complete
	output reg A_c ; //authentication complete
	
	reg [puf_sig_length+valid_byte_offset-1 : 0] expected_sig [IP_COUNT]; // reg [ X] [Y] expected_sig ---> memory element
	reg [data_width+valid_byte_offset-1 : 0] control_sig [IP_COUNT];
	reg [data_width+valid_byte_offset-1 : 0] IP_ID [IP_COUNT];
	reg [parity_bits_width-1: 0] expected_parity_bits [IP_COUNT];
	
	wire [puf_sig_length-1 : 0] expected_sig_data [IP_COUNT];
	wire [valid_byte_offset-1 : 0] expected_sig_valid [IP_COUNT];
	
	wire [data_width-1 : 0] control_sig_data [IP_COUNT];
	wire [valid_byte_offset-1 : 0] control_sig_valid [IP_COUNT];
	
	wire [data_width-1 : 0] IP_ID_data [IP_COUNT];
	wire [valid_byte_offset-1 : 0] IP_ID_valid [IP_COUNT];

	wire [data_width-1:0] corrected_out[puf_sig_length/data_width];
	wire [puf_sig_length-1 : 0] puf_in;

	integer i;
	genvar j;
	generate	
	for (j = 0; j < puf_sig_length/data_width; j = j + 1) begin
		assign puf_in = {corrected_out[j],puf_in[puf_sig_length-1:data_width]};
	end
	endgenerate
	 
	reg ID_found = 1'b0;
    //wire [5 :0]  OutSynCheckBits;
	  	
	integer IP_index=0; //which IP sig is selected this matched with IP ID in the order it is sent
	
	generate
	for (j = 0; j < puf_sig_length/data_width; j = j + 1) begin
		error_module errorX (sig_in[((j+1)*data_width)-1:j*data_width], expected_parity_bits[IP_index][((j+1)*12)-1:j*12], corrected_out[j]);
	end
	endgenerate

	generate
	for (j = 0; j < puf_sig_length/data_width; j = j + 1) begin
		assign expected_sig_data[j] = expected_sig[j][puf_sig_length+valid_byte_offset-1:valid_byte_offset];
		assign expected_sig_valid[j] = expected_sig[j][valid_byte_offset-1:0];

		assign control_sig_data[j] = control_sig[j][data_width+valid_byte_offset-1:valid_byte_offset];
		assign control_sig_valid[j] = control_sig[j][valid_byte_offset-1:0];

		assign IP_ID_data[j] = IP_ID[j][data_width+valid_byte_offset-1:valid_byte_offset];
		assign IP_ID_valid[j] = IP_ID[j][valid_byte_offset-1:0];
	end
	endgenerate

			
	
    always @ (posedge clk)
	begin
		if(~rst ) begin
			Instruction_reg <=32'b 0;
			control_out <= 32'b0;
			comp_out <= 0;
			status <= 32'b0;
			S_c <= 1'b0;
			A_c <= 0;
			
			for(i=0; i<puf_sig_length/data_width; i=i+1) begin
				expected_sig[i] <= {128'd0, 8'b00000001};
				control_sig[i] <= {32'd0, 8'b00000001};
				IP_ID[i] <= {32'd0, 8'b00000001};
				expected_parity_bits[i] <= 48'd0;
			end

		end else begin	 
			
		IP_index = 0;			
		ID_found = 1'b0;

		for(i=0; i<puf_sig_length/data_width; i=i+1) begin
			if(IP_ID_data[i] == IP_ID_in && IP_ID_valid[i][0] != 1'b1) begin
				IP_index = i;
				ID_found = 1'b1;
			end
		end				

		case(Instruction_in)
			`IDLE_IN:
				status <= `IDLE; 
		
			`GEN_CHNG:
			begin
				if (ID_found == 1'b1) begin
					if(control_sig_valid[IP_index][0] != 1'b1) begin
						A_c <= 1'b1;
						control_out <= control_sig_data[IP_index];
					end
					else begin
						A_c <= 1'b0;
						status <= `CHNG_NOT_VALID;
					end
				end
				else begin
					status <= `IP_ID_NOT_FOUND;
					A_c <= 1'b0;
				end
			end
				
			`PROV_ID: //SHIFTING in the IP IDs
			begin
				if(ID_found == 1'b1) begin
					S_c <= 1'b0;
					status <= `IP_PRESENT;
				end
				else begin
					for(i=0; i<puf_sig_length/data_width; i=i+1) begin
						IP_ID[i+1] <= IP_ID[i];
					end
					IP_ID[0][data_width+valid_byte_offset-1:valid_byte_offset] <= IP_ID_in;
					IP_ID[0][0] <= 1'b0;
					S_c <= 1'b1;
				end
			end
			
			`COMPARE: 
			begin
				if (ID_found == 1'b1) begin
					if(expected_sig_valid[IP_index][0] != 1'b1) begin
						if(expected_sig_data[IP_index] == puf_in && sig_valid == 1'b1) begin
							A_c <= 1'b1;
							comp_out <= 1'b1;
						end
						else begin
							A_c <= 1'b1;
							comp_out <= 1'b0;
						end
					end
					else begin
						A_c <= 1'b0;
						status <= `COMP_NOT_VALID;
					end
				end
				else begin
					status <= `IP_ID_NOT_FOUND;
					A_c <= 1'b0;
				end
			end
			
			`PROV_EXP: //Calculating the values for the parity bits but I forget how the math works. each section of i calculated 6 bits of the partity
			begin
				if (ID_found == 1'b1) begin
					expected_sig[IP_index][puf_sig_length+valid_byte_offset-1:valid_byte_offset] <= sig_in;
					expected_sig[IP_index][0] <= 1'b0;
					S_c <= 1'b1;

						for(i=0; i<puf_sig_length/data_width; i=i+1) begin
							expected_parity_bits[IP_index][0+(6*i)] <= sig_in[2+(16*i)] ^ sig_in[5+(16*i)] ^ sig_in[7+(16*i)] ^ sig_in[9+(16*i)] ^ sig_in[11+(16*i)] ^ sig_in[14+(16*i)];
							expected_parity_bits[IP_index][1+(6*i)] <= sig_in[1+(16*i)] ^ sig_in[4+(16*i)] ^ sig_in[7+(16*i)] ^ sig_in[8+(16*i)] ^ sig_in[10+(16*i)] ^ sig_in[13+(16*i)] ^ sig_in[14+(16*i)] ^ sig_in[15+(16*i)];
							expected_parity_bits[IP_index][2+(6*i)] <= sig_in[0+(16*i)] ^ sig_in[4+(16*i)] ^ sig_in[5+(16*i)] ^ sig_in[6+(16*i)] ^ sig_in[9+(16*i)] ^ sig_in[10+(16*i)] ^ sig_in[11+(16*i)] ^ sig_in[12+(16*i)] ^ sig_in[14+(16*i)] ^ sig_in[15+(16*i)];
							expected_parity_bits[IP_index][3+(6*i)] <= sig_in[0+(16*i)] ^ sig_in[1+(16*i)] ^ sig_in[2+(16*i)] ^ sig_in[3+(16*i)] ^ sig_in[4+(16*i)] ^ sig_in[9+(16*i)] ^ sig_in[10+(16*i)] ^ sig_in[11+(16*i)] ^ sig_in[12+(16*i)] ^ sig_in[13+(16*i)] ^ sig_in[14+(16*i)] ^ sig_in[15+(16*i)];
							expected_parity_bits[IP_index][4+(6*i)] <= sig_in[3+(16*i)] ^ sig_in[6+(16*i)] ^ sig_in[8+(16*i)] ^ sig_in[9+(16*i)] ^ sig_in[12+(16*i)]  ^ sig_in[13+(16*i)] ^ sig_in[15+(16*i)];
							expected_parity_bits[IP_index][5+(6*i)] <= sig_in[0+(16*i)] ^ sig_in[1+(16*i)] ^ sig_in[2+(16*i)] ^ sig_in[3+(16*i)] ^ sig_in[4+(16*i)] ^ sig_in[5+(16*i)] ^ sig_in[6+(16*i)] ^ sig_in[7+(16*i)] ^ sig_in[8+(16*i)] ^ sig_in[9+(16*i)] ^ sig_in[14+(16*i)] ^ sig_in[15+(16*i)];
						end
						
				end
				else begin
					status <= `IP_ID_NOT_FOUND;
					S_c <= 1'b0;
				end
			end
			
			`STR_CHNG:
			begin
				if (ID_found == 1'b1) begin
					control_sig[IP_index][data_width+valid_byte_offset-1:valid_byte_offset] <= sig_in[31:0];
					control_sig[IP_index][0] <= 1'b0;
					S_c <= 1'b1;
				end
				else begin
					status <= `IP_ID_NOT_FOUND;
					S_c <= 1'b0;
				end
			end
				
		endcase
		end	
    end

 

endmodule


module error_module(data, parity, corrected_out);
	
	input [31:0] data;
	input [11:0] parity;
	
	wire ContG = 1'b1;
	wire ContH = 1'b0;
	wire ContB = 1'b0;
	wire ContE = 1'b0;
	wire ContF = 1'b1;
	wire ContK = 1'b1;
	wire ContL = 1'b1;
	
	wire [15:0] OutDataBus1;
	wire 	ByteParLo1, ByteParHi1;
	wire [15:0] OutDataBus2;
	wire 	ByteParLo2, ByteParHi2;
	wire UncorrError1, UncorrError2;
    wire [5 :0] OutSynCheckBits;
	
	output [31:0] corrected_out;
	
	assign corrected_out = {OutDataBus2, OutDataBus1};
	
	c1908 error_correction_1 (.InDataBus(data[15:0]), .InCheckBits(parity[5:0]), .InExtSynBits(4'b0000), 
	.ContE(ContE), .ContB(ContB), .ContF(ContF), .ContG(ContG), .ContH(ContH), .ContK(ContK), .ContL(ContL),
	.OutDataBus(OutDataBus1), .ByteParLo(ByteParLo1), .ByteParHi(ByteParHi1), .UncorrError(UncorrError1),
	.OutSynCheckBits(OutSynCheckBits));
	
	c1908 error_correction_2 (.InDataBus(data[31:16]), .InCheckBits(parity[11:6]), .InExtSynBits(4'b0000), 
	.ContE(ContE), .ContB(ContB), .ContF(ContF), .ContG(ContG), .ContH(ContH), .ContK(ContK), .ContL(ContL),
	.OutDataBus(OutDataBus2), .ByteParLo(ByteParLo2), .ByteParHi(ByteParHi2), .UncorrError(UncorrError2),
	.OutSynCheckBits(OutSynCheckBits));
	
endmodule



