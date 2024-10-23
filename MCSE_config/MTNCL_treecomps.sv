//file name "MTNCL_treecomps.sv"
//module list: addtreem, ortreem

//`include "MTNCL_gates.v"
//`include "NCL_gates.v"

// DATE        Version           Description
//5-25-2022      1.0              change import packages at module level and remove `include
//6-9-2022       2.0              change tree_function into local built_in function or 
//                                     function inside module
//9-20-2022      3.0              log_u(x,4) != $clog2($clog2(x)), use log_u function

 //-----------------log_u function--------------// 
		function automatic int log_u (input int L, R);  //L-number; R-base
			var int temp = 1; 
			var int level = 0;
			if (L == 1)
				return 0;
			while (temp < L) begin
				temp = temp * R;
				level = level +1;
			end
			return level;
		endfunction	
 //------------------------------------------------------// 
 
 //-----------------level_number function--------------// 
 //bits to be combined on level of tree of width using base input gates
		function automatic int level_num (input int width, level);
			var int num = width; 
			if (level != 0) begin
			  for (int i=1; i<= level; i=i+1) begin
			    if ( (log_u((num/4+num%4),4) + i) == log_u(width,4) ) begin
				   num = num/4 + num%4;
				end else begin
				   num = num/4+ 1;
				end
			  end
			end
			return num;
		endfunction		
 //------------------------------------------------------// 


//------------module andtreem-------//
//instances list: th22m_a, th33m_a, th44m_a
module 	andtreem #(parameter width = 4) (a, sleep, ko);
  input logic [width-1:0] a;
  input logic sleep;
  output logic ko;

  logic [width-1:0] comp_array [0 : log_u(width,4)]; //log4(width) levels of tree
  
  assign comp_array[0] = a; // RENAME: 
  
  genvar k,j,h;
  generate
    for ( k=0; k<log_u(width,4); k++)  begin       //for each level of the tree
      if (level_num(width,k) > 4) 
	  begin : NOT_LAST             //if the number of input of current level greater than 4
	      //every 4 input one th44m_a
		  for ( j=0; j< (level_num(width,k)/4); j=j+1) 
		  begin :PRINCIPLE
		    th44m_a u1_44(.a(comp_array[k][j*4]), 
			              .b(comp_array[k][j*4+1]), 
					      .c(comp_array[k][j*4+2]), 
					      .d(comp_array[k][j*4+3]), 
					      .s(sleep), 
					      .z(comp_array[k+1][j])
					     );
          end :PRINCIPLE
		  
		  //left over gates
		  if ((log_u(level_num(width,k)/4 + level_num(width,k)%4, 4)+k+1) != log_u(width,4) ) //if copy the signal to next level will cuase tatol tree level increase
		  begin : LEFT_OVER_GATE
		    if (level_num(width,k) % 4 == 2) begin
			  th22m_a u1_22(.a(comp_array[k][level_num(width,k)-2]), 
			                .b(comp_array[k][level_num(width,k)-1]), 
			  		        .s(sleep), 
			  		        .z(comp_array[k+1][level_num(width,k) / 4])
			  		        );
		    end
		    if (level_num(width,k) % 4 == 3) begin
			  th33m_a u1_33(.a(comp_array[k][level_num(width,k)-3]), 
			                .b(comp_array[k][level_num(width,k)-2]),
			                .c(comp_array[k][level_num(width,k)-1]),							
			  		        .s(sleep), 
			  		        .z(comp_array[k+1][level_num(width,k) / 4])
			  		        );
		    end			
          end : LEFT_OVER_GATE	
		  
		  //left over signals 
          if (((log_u(level_num(width,k)/4 + level_num(width,k)%4, 4)+k+1) == log_u(width,4)) & (level_num(width,k)%4 !=0) ) //if copy signal to next level will not increase the total tree-level
		  begin :LEFT_OVER_SINGALS
		      for (h=0; h<(level_num(width,k)%4); h=h+1) begin
			    assign comp_array[k+1][level_num(width,k)/4 +h] = comp_array[k][level_num(width,k) -1-h];
			  end  
          end :LEFT_OVER_SINGALS
          

	  end : NOT_LAST
	  else if (level_num(width,k) == 2) 
	  begin : LAST22
		    th22m_a u1f_22(.a(comp_array[k][0]), 
			               .b(comp_array[k][1]), 
			  		       .s(sleep), .z(ko)
			  		       );
	  end : LAST22 
	  else if (level_num(width,k) == 3) 
	  begin : LAST33
		    th33m_a u1f_33(.a(comp_array[k][0]), 
			               .b(comp_array[k][1]), 
			               .c(comp_array[k][2]), 						   
			  		       .s(sleep), .z(ko)
			  		       );
	  end : LAST33 
	  else if (level_num(width,k) == 4) 
	  begin : LAST44
	    th44m_a u1f_44(.a(comp_array[k][0]), 
			               .b(comp_array[k][1]), 
			               .c(comp_array[k][2]), 	
			               .d(comp_array[k][3]), 							   
			  		       .s(sleep), .z(ko)
			  		       );
	  end : LAST44
    end	 //end for 
  endgenerate
endmodule	//andtreem



//------------module ortreem-------//
//instances list: th12m_a, th13m_a, th14m_a
module 	ortreem #(parameter width = 33) (a, sleep, ko);
  input logic [width-1:0] a;
  input logic sleep;
  output logic ko;

  logic [width-1:0] comp_array [0 : $clog2($clog2(width))]; //log4(width) levels of tree
  
  assign comp_array[0] = a;
  
  genvar k,j,h;
  generate
    for ( k=0; k<$clog2($clog2(width)); k=k+1)  begin       //for each level of the tree
      if (level_num(width,k) > 4) begin             //if the number of input of current level greater than 4
	      //every 4 input one th14m_a
		  for ( j=0; j< (level_num(width,k)/4); j=j+1) begin 
		    th14m_a u1_14(.a(comp_array[k][j*4]), 
			              .b(comp_array[k][j*4+1]), 
					      .c(comp_array[k][j*4+2]), 
					      .d(comp_array[k][j*4+3]), 
					      .s(sleep), 
					      .z(comp_array[k+1][j])
					     );
          end
		  // 
          if ($clog2($clog2(width)) == ($clog2($clog2(level_num(width,k)/4 + level_num(width,k) %4) ) + k +1) | (level_num(width,k)==5)) begin
	        if (level_num(width,k)%4 == 0) begin end
			else begin
		      for (h=0; h<(level_num(width,k)%4); h=h+1) begin
			    assign comp_array[k+1][level_num(width,k)/4 +h] = comp_array[k][level_num(width,k) -1-h];
			  end  
		    end
          end else begin
		    if (level_num(width,k) % 4 == 2) begin
			  th12m_a u1_12(.a(comp_array[k][level_num(width,k)-2]), 
			                .b(comp_array[k][level_num(width,k)-1]), 
			  		        .s(sleep), 
			  		        .z(comp_array[k+1][level_num(width,k) / 4])
			  		        );
		    end
		    if (level_num(width,k) % 4 == 3) begin
			  th13m_a u1_13(.a(comp_array[k][level_num(width,k)-3]), 
			                .b(comp_array[k][level_num(width,k)-2]),
			                .c(comp_array[k][level_num(width,k)-1]),							
			  		        .s(sleep), 
			  		        .z(comp_array[k+1][level_num(width,k) / 4])
			  		        );
		    end			
          end
	  end else if (level_num(width,k) == 2) begin
		    th12m_a u1f_12(.a(comp_array[k][0]), 
			               .b(comp_array[k][1]), 
			  		       .s(sleep), .z(ko)
			  		       );
	  end else if (level_num(width,k) == 3) begin
		    th13m_a u1f_13(.a(comp_array[k][0]), 
			               .b(comp_array[k][1]), 
			               .c(comp_array[k][2]), 						   
			  		       .s(sleep), .z(ko)
			  		       );
	  end else if (level_num(width,k) == 4) begin
			th14m_a u1f_14(.a(comp_array[k][0]), 
			               .b(comp_array[k][1]), 
			               .c(comp_array[k][2]), 	
			               .d(comp_array[k][3]), 							   
			  		       .s(sleep), .z(ko)
			  		       );
	  end  // end outest if
    end	 //end for 
  endgenerate
endmodule	
