module fw_ami (
    input wire clk,
    input wire rst,
    input wire trigger, // Trigger signal
	input wire fw_chipid_rdy,
	input wire fw_expected_hash_rdy,
	input wire [255:0] fw_fsm_out,
    input wire [255:0] encrypted_fw_signature, // Input to Camellia256 is 128 bits
    input wire [255:0] expected_hash, // Expected hash value
	output reg [2:0] fw_instruction,
    output wire [255:0] hash_output,
	output wire [255:0] encrypted_fw_out,
	output wire [255:0] ChipID_out
);
	reg [255:0] hash_r; 
	reg [255:0] ChipID_r;
	reg counter; 
	reg [255:0] fw_r; // stores the inputed fw value 
	/*
    wire [127:0] decrypted_output; // Output from Camellia256 is 128 bits
    wire [447:0] padded_output; // Decrypted output padded to 448 bits
    wire [63:0] original_length; // Length of original data in bits
    wire [511:0] sha256_input; // Input to SHA256 hashing
	*/
	/*
    // Camellia256 decryption
    camellia camellia_inst (
        .clk(clk),
        .reset(rst),
        .data_in(encrypted_input),
        .data_out(decrypted_output),
		.key(key)
    );
	*/
	
	/*
    // Padding
    assign padded_output = {decrypted_output, 319'b0, 1'b1};
    assign sha256_input = {padded_output, original_length};

    // SHA256 hashing
    sha256 sha256_inst (
        .clk(clk),
        .rst(rst),
        .input(sha256_input),
        .output(hash_output)
    );
	*/
	//assign ChipID_out = ChipID_in; 
	assign encrypted_fw_out = fw_r;
	assign hash_output = hash_r; 
	assign ChipID_out = ChipID_r; 
	
	reg flag;
	
    // Compare hash_output with expected_hash
    always @(posedge clk or posedge rst) begin
        if (rst) begin
			fw_instruction <= 3'b000;
			hash_r <= 'h0;
			ChipID_r <= 'h0;
			counter <= 0;
			flag <= 0;
		end
		else begin
			fw_instruction <= 'b000;
			if (trigger) begin
				fw_instruction <= 'b001; // instruction for decrypting fw_input 
				fw_r <= encrypted_fw_signature; 
			end
			else if (fw_chipid_rdy) begin
				if (counter == 0) begin
					ChipID_r <= fw_fsm_out;
					counter <= counter + 1;
				end
				else begin
					ChipID_r <= fw_fsm_out;
				end  
			end 
			else if (fw_expected_hash_rdy) begin
				hash_r <= fw_fsm_out;
				flag <= 1;
			end 
			
			if (flag == 1) begin
				if (expected_hash == hash_r) begin
					fw_instruction <= 'b100; // instruction for if the fw hash matches the hash on ami 
					
				end 
				else begin
					fw_instruction <= 'b010; // instruction for if the fw hash does not matche the hash on ami 
				end 
				flag <= 0;
			end 
		end 
    end
endmodule
