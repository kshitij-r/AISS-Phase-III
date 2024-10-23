module apc_wrapper(
    input                      clk,
    input                      rst_n,
    input                      apc_select,
    input [255:0]              chip_id_to_apc,

    // APC to Boot Control
    input                      apc_data_req,
    input                      apc_sleep_out_aes,
    input                      apc_data_out_valid_aes,
    input                      apc_data_out_aes,

     // Boot Control to APC
    output logic                         apc_data_in,
    output logic                         apc_data_in_valid,
    output logic                         apc_word_en,
    output logic                         core_reset,

    output logic                         apc_encryption_done,

    output logic [255:0]                 encrypted_chip_id_from_apc
);


logic [611:0] input_data;
logic [127:0] store_out_data;
logic done = 0;

integer x;
integer out_count;
integer counter;

assign input_data[255:0] = 256'h49361d1ee0abd2c572b0edf565a9984c3ed4923ab2f88cd6b0eaa30d0c13ef1b; //key
assign input_data[611:385] = 'h0;
assign input_data[384] = 'h0;



always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        x <= 0;
        out_count <= 0;
        counter <= 0;
        apc_word_en <= 1'b0;
        apc_data_in_valid <= 1'b0;
        apc_data_in <= '0;
        store_out_data <= 128'b0;
        done <= 0;
        core_reset = 1'b1;
    end
    else begin
        if (apc_select) begin
            if (~done) begin
            case (counter)
            0: begin
                // Load first chunk
                input_data[383:256] = chip_id_to_apc[255:128];  // First 128-bit chunk
                if (x == 612) begin
                    apc_word_en <= 1'b1;
                    apc_data_in_valid <= 1'b0;
                    apc_data_in <= 1'b0;
                    x <= 0;
                    out_count <= 0;
                    core_reset <= 1'b0;
                    counter <= counter + 1;
                end else begin
                    core_reset <= 1'b1;
                    apc_word_en <= 1'b0;
                    apc_data_in_valid <= 1'b1;
                    apc_data_in <= input_data[x];
                    x <= x + 1;
                end
            end

            1: begin
                core_reset <= 1'b0;
                if (apc_data_out_valid_aes == 1) begin
                    store_out_data[out_count] = apc_data_out_aes;
                    out_count <= out_count + 1;
                    if (out_count == 127) begin
                        encrypted_chip_id_from_apc[255:128] <= store_out_data;
                        counter <= counter + 1;
                    end
                end
            end

            2: begin
                // Load second chunk
                input_data[383:256] = chip_id_to_apc[127:0];  // Second 128-bit chunk
                if (x == 612) begin
                    apc_word_en <= 1'b1;
                    apc_data_in_valid <= 1'b0;
                    apc_data_in <= 1'b0;
                    x <= 0;
                    out_count <= 0;
                    core_reset <= 1'b0;
                    counter <= counter + 1;
                end else begin
                    core_reset <= 1;
                    apc_word_en <= 1'b0;
                    apc_data_in_valid <= 1'b1;
                    apc_data_in <= input_data[x];
                    x <= x + 1;
                end
            end

            3: begin
                if (apc_data_out_valid_aes == 1) begin
                    store_out_data[out_count] = apc_data_out_aes;
                    out_count <= out_count + 1;
                    if (out_count == 127) begin
                        encrypted_chip_id_from_apc[127:0] <= store_out_data;
                        counter <= counter + 1;
                    end
                end
            end

            4: begin
                // Done processing both chunks
                apc_encryption_done = 1;
                done <= 1;  
            end
        endcase
    end
 end
    end
end



endmodule 