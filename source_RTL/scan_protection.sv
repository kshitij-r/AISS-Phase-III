// scan protection key = 256'h87A5E932FA1BC49DFF8A0B2C3D4E5F607891ABCDEF0123456789ABCDEF012345;

module vim_scan_control#(    
    parameter scan_key_width = 32,
    parameter scan_key_number = 8
)(
    input  logic                             clk, 
    input  logic                             rst_n,
    input  logic     [scan_key_width-1:0]    scan_key,
    output logic                            scan_unlock
);

reg [$clog2(scan_key_number):0] key_address;
reg [scan_key_width-1:0] scan_protection_key;

always@(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        scan_unlock <= 0 ;
        key_address <= 0;
    end else begin
        if(scan_unlock == 0) begin
            if(scan_key == scan_protection_key) begin
                key_address <= key_address + 1;
                // $displayh("scan protection key =", scan_protection_key);
            end
            if(key_address == scan_key_number) begin
                scan_unlock <= 1;
            end
        end 
    end
end


always@(*) begin
    scan_protection_key = 'hEF012345;
    case(key_address) 
        0: begin
            scan_protection_key = 'hEF012345;
        end
        
        1: begin
           scan_protection_key = 'h6789ABCD;
        end
        
        2: begin
            scan_protection_key = 'hEF012345;
        end
        
        3: begin
            scan_protection_key = 'h7891ABCD;
        end
        
        4: begin
            scan_protection_key = 'h3D4E5F60;
        end
        
        5: begin
            scan_protection_key = 'hFF8A0B2C;
        end
        
        6: begin
           scan_protection_key = 'hFA1BC49D;
        end
        
        7: begin
            scan_protection_key = 'h87A5E932;
        end
        
    endcase
end


endmodule 