
module lifecycle_protection (

    input  logic         clk,
    input  logic         rst_n,
    input  logic         lc_transition_request,
    input  logic [255:0] lc_identifier,

    output logic         lc_success,
    output logic         lc_done, 
    output logic [2:0]   lc_state
);

/*
1. Store all lifecycle states
2. Control transition mechanism
3. Develop transition change effect on memory and assets
4. Lifecycle transition via an authentication mechanism 
*/


reg [255:0] identifier_r;
reg [2:0] lc_r;

logic [255:0] currOwnerSignature; 

logic rd_en, valid; 

lc_memory  #(.WIDTH(256), .LENGTH(6)) memory (.clk(clk), .rst_n(rst_n), .rd_en(rd_en), .addr(lc_state), .rdData(currOwnerSignature), .valid(valid));

typedef enum logic [1:0] {START, TRANSITION_AUTH, FINISH} state_t;
state_t state_r;

assign lc_state = lc_r; 

always@(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        state_r <= START; 
        lc_r <= 3'b001;   
        lc_success <= 1'b0; 
        lc_done <= 0; 
    end 
    else begin
        case (state_r) 
            START : begin
                // Wait for lc transition request 
                if (lc_transition_request == 1'b1) begin
                    identifier_r <= lc_identifier; // Register the identifier 
                    state_r <= TRANSITION_AUTH; 
                    rd_en <= 1; 
                end 
            end
            TRANSITION_AUTH : begin
                // Compare identifer with with golden identifier, ensure lc is not end of life 
                if (valid) begin 
                    if (identifier_r == currOwnerSignature && lc_r < 3'b101) begin 
                        // Increment lc state, assert success 
                        lc_r <= lc_r + 1; 
                        lc_success <= 1'b1; 
                        lc_done <= 1; 
                        state_r <= FINISH; 
                    end 
                    else begin
                        // If not correct identifer, ignore request 
                        lc_success <= 1'b0;
                        identifier_r <= 0;
                        lc_done <= 1; 
                        state_r <= FINISH;
                    end 
                end 
            end 
            FINISH : begin 
                rd_en <= 0; 
                // Wait until transition request is deasserted 
                if (lc_transition_request == 1'b0) begin
                    // Deassert success and go back to start
                    lc_done <= 0;  
                    lc_success <= 1'b0; 
                    state_r <= START;
                end 
            end 
        endcase
    end 
end

endmodule