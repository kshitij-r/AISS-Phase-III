`timescale 1 ns / 100 ps

module fsm_top_testing_tb;
	logic clk = 0, rst;
	logic [255:0] jtag_in;
	logic [255:0] mem_data_out;
	logic [255:0] ami_out;
	logic [2:0] ami_ack;
	logic [255:0] fsm_ami;
	
	logic  [23:0] gpio_in;
	logic [23:0] gpio_out;
	logic [23:0] gpio_en;
	logic 	        gpio_irq;    
	logic [31:0]   gpio_ilat;
	integer count;
	integer j;
	
	logic [255:0]   cam_key;
	
	logic [255:0] oem_input;
	logic [255:0] ami_output;
	logic fw_trigger;
	logic [255:0] hash_output;
	logic [255:0] ami_input;
	logic [255:0] ta2_bus;
	
	fsm_top DUT (.*);
	
	initial begin :generate_clock
	
		while (1)
			#5 clk = ~clk;
	end	
	
	logic [255:0] currOwnerID = 'h6fd96edf3aca42bb949f38f555f42d4f422f705cf445e3d8a5fcca3052933eb3;
	logic [255:0] AMI_SentrySiliconID = 'h0;
	logic [255:0] AMI_CompositeIPID = 'h0;
	logic ChipIDRegistered = 0;
	logic [2:0] AMI_lifecycle = 'h0;
	logic lifecycleRegistered = 0;
	logic newLifeCycleRegistered = 0;
	logic OEMAuthentication = 0;
	logic OEMSentrySiliconAuth = 0;
	logic OEMCompositeIPIDAuth = 0;
	logic OEMFailedAuth = 0;
	logic OEMLifecycleAuth = 0;
	logic OEMcurrOwnerCheck = 0;
	logic lifecycleRegistered1 = 0;
	logic newLifeCycleRegistered1 = 0;
	
	logic firmwareSignatureRegistered = 0;
	logic secureCommunicationKeyRegistered = 0;
	logic JTAGProtectionKeyRegistered = 0;
	logic OwnershipAuthenticationKeyRegistered = 0;
	logic CompositeWatermarkRegistered = 0;
	logic ChipManufacturerIDRegistered = 0;
	logic SystemIntegratorIDRegistered = 0;
	logic lifecycleOEMAUTH = 0;
	logic AMI_AUTH1 = 0;
	logic DeploymentLifecycleRegistered = 0;
	
	logic [255:0] firmwareSignature = 'h0;
	logic [255:0] secureCommunicationKey = 'h0;
	logic [255:0] JTAGProtectionKey = 'h0;
	logic [255:0] OwnershipAuthenticationKey = 'h0;
	logic [255:0] CompositeWatermark = 'h0;
	logic [255:0] ChipManufacturerID = 'h0;
	logic [255:0] SystemIntegratorID = 'h0;
	
	logic [15:0] array [160:0];
	logic [15:0] array1 [160:0];
	logic [255:0] fw_fsm_out;
	//byte array[159];
	int k = 0;
	
	logic valid = 1;
	
	initial begin 
		// pregenerate the IP ID signatures 
		ami_ack = 0;
		ami_out = 0;
		gpio_in = 0;
		j = 0;
		while (j<10) begin
			for (integer i = 0; i < 16; i = i + 1) begin
				//@(posedge clk);
					//gpio_in[23:8] = $urandom_range(0,65536);
					array[k] = $urandom_range(0,65536);
					k = k + 1;
			end 
			j = j + 1;
			//@(posedge clk); 
		end 
		
		jtag_in = 'h0;
		$timeformat(-9, 0, " ns");
		
		// clock cycles to fully reset system 
		rst = 1'b1;
		@(posedge clk);
		
		
		 for(integer i=0; i< 10 ; i++) begin
			@(posedge clk);
		end
		
		@(posedge clk);
		@(posedge clk);
		
		// start of the simulation
		rst = 0 ;
		@(posedge clk);
		
		count = 0;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// at this point, SENTRY is encryption the Sentry Silicon ID, and the testbench
		// will wait until SENTRY is ready to extract the IP IDs from TA2 
		
		while (gpio_out[2] != 1'b1) begin // wait until bus wakeup
			@(posedge clk);
			
		end 
		
		
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk); 
		
		gpio_in[3] = 1; // send bus wakeup acknowledgment 
		@(posedge clk);
		gpio_in[3] = 0; 
		
		while (gpio_out[4] != 1) begin // SENTRYs go signal for IP ID extraction. Testbench will now send the IP IDs through the gpio_in
			@(posedge clk); 
		end 
		j=0;
		k=0;
		//if (gpio_out[3] == 1) begin 
			while (j<10) begin
				for (integer i = 0; i < 18; i = i + 1) begin
					if (i == 0) begin
						//transmissions = 0; 
						gpio_in[23:8] = 16'h7A7A;
						@(posedge clk);
						continue;
					end 
					else if (i == 17) begin
						//transmissions = 0; 
						gpio_in[23:8] = 16'hB9B9;
						@(posedge clk);
						continue;
					end else begin 
						gpio_in[23:8] = array[k];
						//array[k] = gpio_in[23:8];
						k = k + 1;
						//transmissions = transmissions + 1;
						@(posedge clk);
					end 
				end 
				j = j + 1;
				//@(posedge clk); 
			end 
		//end 
		
		//during these clock cycles, SENTRY will hash all IP IDs to create the Composite IP ID and will then encrypt it. 
		while(count < 149)
		begin
			@(posedge clk);
			count++;
		end 
		
		count = 0;
		
		// The communication protocol with the AMI is not developed. To communicate with the testbench, 
		// the FSM will use the fsm_ami signal to send data to it. Every sequence will happen in order so that
		// the testbench knows what is happening. First, the Chip ID will be registered with AMI.
		// Chip ID = {Sentry Silicon ID, Composite IP ID}
		// This will take place over two cycles. Next, the AMI will send an acknowledgment package 
		// on the ami_ack signal once it successfully receives it. Next, SENTRY will register all on-chip assets
		// with the AMI sequentially. To do this, SENTRY will fetch the asset from memory, encrypt it, register it 
		// with the AMI, wait for the AMI acknowledgment, and then move on to the next asset. Once the final asset is 
		// registered, SENTRY will write the lifecycle state to memory and then register it with the AMI. 
		
		// Once registration is complete, SENTRY will allow the SoC to boot using a GPIO pin and then will start polling for inputs. 
		// SENTRY will poll for a lifecycle transition request through the JTAG port. A request has 3 bits that are used
		// to indicate that it is a lifecycle transition request and the next 3 bits show what lifecycle the request is for. 
		// If the request is valid (a subsequent lifecycle), the request is serviced. SENTRY will change the lifecycle state
		// on the on-chip memory and will then register it with the AMI. The SoC will then be restarted using a GPIO pin and 
		// will then be booted into the next lifecycle and this is where the simulation ends. 
		
		// AMI successful acknowledgment 	ami_ack = 'b100;
		// AMI failure 			 			ami_ack = 'b010;
		// This while loop is all the logic needed for registration during the Manufacture and Testing lifecycle	
		// Communication between the AMI and SENTRY at this point does not need to be encrypted. However, I encrypt all communication
		// except when SENTRY registers the lifecycle state. Doing all this encryption helps to simplify the FSM. 
		while (count < 1500) begin
			
			
			
			if (!ChipIDRegistered) begin
				//$display(fsm_ami);
				//if (fsm_ami == 'h0) begin
					AMI_SentrySiliconID = fsm_ami;
					$display("Sentry Silicon ID");
					$displayh(fsm_ami);
					@ (posedge clk);
					AMI_CompositeIPID = fsm_ami;
					$display("Composite IP ID");
					$displayh(fsm_ami);
					ami_ack = 'b100;
					ChipIDRegistered = 1;
					$display("ChipID Registered");
					@(posedge clk); ami_ack = 'b00; @(posedge clk);	@(posedge clk); @(posedge clk); 	
					
				//end
			end
			else if (!firmwareSignatureRegistered) begin
				if (fsm_ami != 'h0) begin
					firmwareSignature = fsm_ami;
					firmwareSignatureRegistered = 1;
					ami_ack = 'b100;
					$display("Firmware Signature Registered");
					$displayh(firmwareSignature);
					@(posedge clk); ami_ack = 'b000; @(posedge clk);@(posedge clk); @(posedge clk); 
				end 
			end 
			else if (!secureCommunicationKeyRegistered) begin
				if (fsm_ami != 'h0) begin
					secureCommunicationKey = fsm_ami;
					secureCommunicationKeyRegistered = 1;
					ami_ack = 'b100;
					$display("Secure Communications Key Registered");
					$displayh(secureCommunicationKey);
					@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk); @(posedge clk); 
				end 
			end 
			else if (!JTAGProtectionKeyRegistered) begin
				if (fsm_ami != 'h0) begin
					JTAGProtectionKey = fsm_ami;
					JTAGProtectionKeyRegistered = 1;
					ami_ack = 'b100;
					$display("JTAG Protection Key Registered");
					$displayh(JTAGProtectionKey);
					@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk); @(posedge clk); 
				end 
			end
			else if (!OwnershipAuthenticationKeyRegistered) begin
				if (fsm_ami != 'h0) begin
					OwnershipAuthenticationKey = fsm_ami;
					OwnershipAuthenticationKeyRegistered = 1;
					ami_ack = 'b100;
					$display("Ownership Authentication Key Registered");
					$displayh(OwnershipAuthenticationKey);
					@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk); @(posedge clk); 
				end 
			end
			else if (!CompositeWatermarkRegistered) begin
				if (fsm_ami != 'h0) begin
					CompositeWatermark = fsm_ami;
					CompositeWatermarkRegistered = 1;
					ami_ack = 'b100;
					$display("Composite Watermark Key Registered");
					@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk); @(posedge clk); 
				end 
			end
			else if (!ChipManufacturerIDRegistered) begin
				if (fsm_ami != 'h0) begin
					ChipManufacturerID = fsm_ami;
					ChipManufacturerIDRegistered = 1;
					ami_ack = 'b100;
					$display("Chip Manufacturer ID Registered");
					$displayh(ChipManufacturerID);
					@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk); @(posedge clk); 
				end 
			end
			else if (!SystemIntegratorIDRegistered) begin
				if (fsm_ami != 'h0) begin
					SystemIntegratorID = fsm_ami;
					SystemIntegratorIDRegistered = 1;
					ami_ack = 'b100;
					$display("System Integrator ID Registered");
					$displayh(SystemIntegratorID);
					@(posedge clk); ami_ack = 'b000; @(posedge clk);@(posedge clk); @(posedge clk); 
				end 
			end
			else if (!lifecycleRegistered) begin
				//ami_ack = 'b111;
				if (fsm_ami != 'h0) begin
					AMI_lifecycle = fsm_ami[2:0];
					//@(posedge clk);
					ami_ack = 'b100;
					lifecycleRegistered = 1;
					$display("Testing Lifecycle Registered");
					@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk); @(posedge clk);
					$display(AMI_lifecycle);
				end 
			end
			else if (!newLifeCycleRegistered) begin
				$display("Lifecycle Transition Request Incoming...Servicing");
				jtag_in = 'b010010;
				@(posedge clk);
				if (fsm_ami != 'h0) begin
					AMI_lifecycle = fsm_ami[2:0];
					newLifeCycleRegistered = 1;
					ami_ack = 'b100;
					
					@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk);
					//$stop;
					jtag_in = 0;
					break;
					
				end 
			end
			count++;
			@(posedge clk);
		end 
		count = 0;
		
		// FSM will then restart and boot into the OEM lifecycle
		
		/*
		The secure boot during the OEM lifecyle will now take place. This consists of authenticating the ChipID, lifecycle state and the
		Current Owner ID. The ChipID generation is identical to the previous lifecycle. SENTRY will send it to the AMI, fetch and encrypt 
		the lifecycle state, and if those two are correct than the AMI will send an acknowledgment packet. Once the acknowledgment is received,
		SENTRY will fetch and encrypt the Current Owner ID (Ownership authentication key) and will then wait for the acknowledgment. Once the 
		successful acknowledgment is received, SENTRY will allow the SoC to boot by using a GPIO Pin.
		
		*/
		//wait until IP ID generation again, same process
		while (gpio_out[2] != 1'b1) begin // wait until bus wakeup
			@(posedge clk);
			//count++;
		end 
		
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk); 
		
		gpio_in[3] = 1; // send bus wakeup acknowledgment 
		@(posedge clk);
		gpio_in[3] = 0; 
		
		while (gpio_out[4] != 1) begin // SENTRYs go signal for IP ID extraction. Testbench will now send the IP IDs through the gpio_in
			@(posedge clk); 
		end 
		
		j=0;
		k=0;
		//if (gpio_out[3] == 1) begin 
			while (j<10) begin
				for (integer i = 0; i < 18; i = i + 1) begin
					if (i == 0) begin
						//transmissions = 0; 
						gpio_in[23:8] = 16'h7A7A;
						@(posedge clk);
						continue;
					end 
					else if (i == 17) begin
						//transmissions = 0; 
						gpio_in[23:8] = 16'hB9B9;
						@(posedge clk);
						continue;
					end else begin 
						gpio_in[23:8] = array[k];
						//array[k] = gpio_in[23:8];
						k = k + 1;
						//transmissions = transmissions + 1;
						@(posedge clk);
					end 
				end 
				j = j + 1;
				//@(posedge clk); 
			end 
		//end 
		
		// authentication of chip id and lifecycle state 
		while (fsm_ami == 0) begin
			@(posedge clk); 
		end
		
		// These if statements will check if the ChipID stored on the AMI is the same as the one being sent now 
		$display("Chip ID Authentication");
		$displayh(fsm_ami);
		if (fsm_ami == AMI_SentrySiliconID) begin
			valid = 1;
		end 	
		else begin
			valid = 0;
		end 
		@(posedge clk); 
		
		$displayh(fsm_ami);
		if (fsm_ami == AMI_CompositeIPID) begin
			valid = 1;
		end 	
		else begin
			valid = 0;
		end 
		@(posedge clk); 
		
		while(fsm_ami == 0) begin
			@(posedge clk); 
		end 
		
		$display("Encrypted Lifecycle State Value"); 
		$displayh(fsm_ami);
		
		// This is the value of the encrypted lifecycle state for OEM = 'b010
		if (fsm_ami == 'h361a686de5a5df47e0f125c15e205f36ca7245290a4220514e6b46fac3950de8) begin // This is the hardcoded encrypted value of 'b010
			valid = 1;
		end 
		else begin
			valid = 0;
		end 
		
		if (valid == 1) begin // if Encrypted Lifecycle State and Chip ID passed, send successful authentication 
			$display("Encrypted Lifecycle State and Chip ID passed");
			ami_ack = 'b100;	
			@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk);
		end 
		else begin
			ami_ack = 'b010;	
			@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk);
		end 
		
		while(fsm_ami == 0) begin
			@(posedge clk);
		end 
		
		$display("Encrypted Current Owner ID Value");
		$displayh(fsm_ami);
		
		if (fsm_ami == OwnershipAuthenticationKey) begin // Check the current owner id with the one stored on AMI 
			valid = 1;
		end 
		else begin
			valid = 0;
		end 
		
		if (valid == 1) begin
			$display("Current Owner ID Authentication Passed");
			ami_ack = 'b100;	// authentication for current owner ID 
			@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk);
		end 
		else begin
			ami_ack = 'b010;	
			@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk);
		end 
		
		$display("Secure Boot Complete...Allow SoC to Boot");
		
		for (int i = 0; i < 10; i++) begin
			@(posedge clk);
		end 
		
		// SoC has now been booted on the OEM lifecycle. 
		
		$display("AMI Requesting to Authenticate System Integrator ID");
		// The request is a 6 bit packet on ami_out. When bits [5:3] are 'b100, SENTRY knows it is an authentication request. 
		// Bits [2:0] indicate the address of the asset to be authenticated. SENTRY will ignore the request if there should 
		// not be access to it during that lifecycle.
		// The assets that can be authenticated during the OEM lifecycle are System Integrator ID, Chipmanufacturer ID, Composite Watermark
		
		/*
		Address | Asset 
		'h00 | SENTRY Firmware Signature
		'h01 | Secure Communication Key
		'h02 | Scan/JTAG protection Key
		'h03 | Ownership Authenticate Key
		'h04 | Composite Watermark
		'h05 | Chip Manufacturer ID
		'h06 | System Integrator ID
		'h07 | Lifecycle State 
		*/
		
		ami_out = 'b100110; // system integrator id authentication request 
		@(posedge clk);
		@(posedge clk); 
		ami_out = 'h0;
		
		while (fsm_ami == 0) begin
			@(posedge clk);
		end 
		
		$display("Encrypted System Integrator ID");
		$displayh(fsm_ami);
		
		if (fsm_ami == SystemIntegratorID) begin // Check the System Integrator ID value with the one stored on AMI 
			valid = 1;
		end 
		else begin
			valid = 0; 
		end 
		
		if (valid == 1) begin 
			$display("System Integrator ID Authentication Passed"); 
			ami_ack = 'b100;	// authentication for system integrator id
			@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk);
		end 
		else begin 
			ami_ack = 'b010;	
			@(posedge clk); ami_ack = 'b000; @(posedge clk); @(posedge clk);
		end 
		
		
		for (int i = 0; i < 10; i++) begin
			@(posedge clk); 
		end 
		
		$stop;
	end
	
	
endmodule 