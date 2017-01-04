
//........... NOC_Bus Master ........

module noc(nocif.md n, crc_if.dn c);

logic [99:0] Data_F_In, Data_F_Out;
logic [31:0] address_noc;
logic [31:0] Wr_Data;
logic [7:0]  length_field;
logic [7:0]  DataW_reg;
logic [7:0]  ctrl_command, ctrl_command_byte;
logic [7:0]  source_id;
logic [3:0]  pstate, nstate;		
bit len, write_en, read_en;
logic [6:0]  pstate2, nstate2;
logic [7:0]  source_id2, return_id2;
logic [7:0]  ctrl_command2;
logic [31:0] address_noc2, address_noc_fl;
logic [31:0] Wr_Data2;
logic [7:0]  length_field_A;
logic [31:0] tmp1, tmp2, tmp3, tmp4;
logic [31:0] chain, start_chain;
logic [31:0] Link_reg, Seed_reg, Control_reg, Poly_reg, Data_for_bm, Data_reg_fl, Length_reg, Length_reg_fl, Result_reg, Message_reg, crc_write, crc_write_fl;
logic [7:0] crc_counter, crc_counter_fl;
logic [31:0] crc_check;
bit bm_mode, flag, flag2;

parameter IDLE = 4'b0000;  
parameter SOURCE_ID = 4'b0001;  
parameter ADDRESS_1 = 4'b0010;  
parameter ADDRESS_2 = 4'b0011;  
parameter ADDRESS_3 = 4'b0100;  
parameter ADDRESS_4 = 4'b0101;  
parameter LENGTH_ST = 4'b0110;  
parameter WDATA_1 = 4'b0111;  
parameter WDATA_2 = 4'b1000;  
parameter WDATA_3 = 4'b1001;  
parameter WDATA_4 = 4'b1010;  
parameter TEST1 = 4'b1011;  

parameter IDLE_2 = 6'b000000; 

// ...FIFO...

fifo f1 (.clk(n.clk), .rst(n.rst), .write_en(write_en), .fifo_in(Data_F_In), .read_en(read_en), .fifo_out(Data_F_Out), .full(full), .empty(empty));


always @(posedge n.clk or posedge n.rst)
begin
      if(n.rst)
      begin
        DataW_reg = 0;
        ctrl_command_byte = 0;
        address_noc_fl     = 0;
        Length_reg_fl	  = 0;
        Data_reg_fl	  = 0;
        crc_counter_fl  = 0;
        crc_write_fl  = 0;
        pstate   = IDLE;
        pstate2 = IDLE_2;
      end
      else
      begin
        DataW_reg = n.DataW;
        ctrl_command_byte  = ctrl_command;
        address_noc_fl     = address_noc2;
        pstate   = nstate;
        pstate2 = nstate2;
        return_id2	  = source_id2;  // This return_id2 is used in the read_resp_returnid for returning the ID.
        Length_reg_fl	  = Length_reg;
        Data_reg_fl	  = Data_for_bm;
        crc_counter_fl  = crc_counter;
        crc_write_fl  = crc_write;
      end
end


// .............combinational block...............

always @(*)
begin
      case(pstate)
            IDLE:
            begin
                    if(n.CmdW == 1)
                    begin
                            ctrl_command = DataW_reg;

                            if(DataW_reg[7:5] == 3'b000) nstate = IDLE;
                            else 
                            begin
                                    nstate = SOURCE_ID;
                                    len = DataW_reg[4];
                            end
                    end

                    write_en = 0;  
                    //read_en = 1;
            end

            SOURCE_ID:
            begin
                    source_id	= DataW_reg;
                    nstate	= ADDRESS_1;
            end

            ADDRESS_1:
            begin
                    if(ctrl_command[3:0] == 4'b1000)
                    begin
                            address_noc[7:0] = DataW_reg;
                            address_noc[31:8] = 24'hffffff;

                            nstate	= LENGTH_ST;
                    end
                    else
                    begin
                            address_noc[7:0] = DataW_reg;
                            nstate	= ADDRESS_2;
                    end
           end

           ADDRESS_2:
           begin
                    address_noc[15:8]	= DataW_reg;
                    nstate	= ADDRESS_3;
           end

           ADDRESS_3:
           begin
                    address_noc[23:16]	= DataW_reg;
                    nstate	= ADDRESS_4;
           end

           ADDRESS_4:
           begin
                    address_noc[31:24]	= DataW_reg;
                    nstate	= LENGTH_ST;
           end

           LENGTH_ST:
           begin
                    length_field = DataW_reg;

                    if(ctrl_command_byte[7:5] == 3'b001)
                    begin
                            write_en = 1;
                            //read_en = 0;  
                            Data_F_In = {12'b0, ctrl_command, source_id, address_noc, length_field, 32'b0};
                            nstate = IDLE;
                    end
                    else if	(ctrl_command_byte[7:5] == 3'b011)
                    begin
                            nstate = WDATA_1;
                    end
                    else 
                            nstate = IDLE;

           end

           WDATA_1:
           begin
                    if(address_noc == 32'hffff_fff0)
                    begin
                            chain[7:0] = DataW_reg;
                    end
                    else if	(address_noc == 32'hffff_fff4)
                    begin
                            start_chain[7:0] = DataW_reg;
                    end
                    else
                    begin
                            Wr_Data[7:0] = DataW_reg;
                    end
                            nstate = WDATA_2;
          end

          WDATA_2:
          begin
                    if(address_noc == 32'hffff_fff0)
                    begin
                            chain[15:8] = DataW_reg;
                    end
                    else if	(address_noc == 32'hffff_fff4)
                    begin
                            start_chain[15:8] = DataW_reg;
                    end
                    else
                    begin
                            Wr_Data[15:8] = DataW_reg;
                    end

                    nstate = WDATA_3;
        end

        WDATA_3:
        begin
                    if(address_noc == 32'hffff_fff0)
                    begin
                            chain[23:16] = DataW_reg;
                    end
                    else if	(address_noc == 32'hffff_fff4)
                    begin
                            start_chain[23:16]	= DataW_reg;
                    end
                    else
                    begin
                            Wr_Data[23:16] = DataW_reg;
                    end

                    nstate = WDATA_4;
        end

        WDATA_4:
        begin
                    if(address_noc == 32'hffff_fff0)
                    begin
                            chain[31:24] = DataW_reg;
                            flag = 0;
                    end
                    else if	(address_noc == 32'hffff_fff4)
                    begin
                            start_chain[31:24]	= DataW_reg;
                    end
                    else
                    begin
                            Wr_Data[31:24]	= DataW_reg;
                            write_en = 1;
                            //read_en = 0;  
                            Data_F_In = {12'b0, ctrl_command, source_id, address_noc, length_field, Wr_Data};
                            //nstate ..;
                    end

                    nstate = IDLE;
        end


    endcase
end


//..............................................................................................................................




parameter READ_ST2_1 = 6'b000001; 
parameter READ_ST2_2 = 6'b000010; 
parameter READ_ST2_3  = 6'b000011; 
parameter ReadResponse_code = 6'b000100; 
parameter ReadResponse_returnid  	= 6'b000101;  
parameter ReadResponse_tmp1_data1 = 6'b000110;  
parameter ReadResponse_tmp1_data2 = 6'b000111;  
parameter ReadResponse_tmp1_data3 = 6'b001000;  
parameter ReadResponse_tmp1_data4 = 6'b001001;  
parameter ReadResponse_tmp2_data1	= 6'b001010;  
parameter ReadResponse_tmp2_data2	= 6'b001011;  
parameter ReadResponse_tmp2_data3	= 6'b001100;  
parameter ReadResponse_tmp2_data4	= 6'b001101;  
parameter ReadResponse_tmp3_data1 = 6'b001110;  
parameter ReadResponse_tmp3_data2 = 6'b001111;  
parameter ReadResponse_tmp3_data3  = 6'b010000;  
parameter ReadResponse_tmp3_data4 = 6'b010001;  
parameter END			= 6'b010010;  
parameter WRITE_ST2 = 6'b010011;  
parameter WriteResponse_code = 6'b010100;  
parameter WriteResponse_returnid	= 6'b010101;  

parameter code_for_bm			= 6'b010110;  
parameter SID_bm		= 6'b010111;  
parameter addr1_bm		= 6'b011000;  
parameter addr2_bm		= 6'b011001;  
parameter addr3_bm		= 6'b011010;  
parameter addr4_bm		= 6'b011011;  
parameter len_bm			= 6'b011100;  
parameter SID_rd_bm	= 6'b011101;  
parameter link1_bm		= 6'b011110;  
parameter link2_bm		= 6'b011111;  
parameter link3_bm		= 6'b100000;  
parameter link4_bm		= 6'b100001;  
parameter seed1_bm		= 6'b100010;  
parameter seed2_bm		= 6'b100011;  
parameter seed3_bm		= 6'b100100;  
parameter seed4_bm		= 6'b100101;  
parameter ctrl1_bm		= 6'b100110;  
parameter ctrl2_bm		= 6'b100111;  
parameter ctrl3_bm		= 6'b101000;  
parameter ctrl4_bm		= 6'b101001;  
parameter poly1_bm		= 6'b101010;  
parameter poly2_bm		= 6'b101011;  
parameter poly3_bm		= 6'b101100;  
parameter poly4_bm		= 6'b101101;  
parameter data1_bm		= 6'b101110;  
parameter data2_bm		= 6'b101111;  
parameter data3_bm		= 6'b110000;  
parameter data4_bm		= 6'b110001;  
parameter len1_bm 		= 6'b110010;  
parameter len2_bm 		= 6'b110011;  
parameter len3_bm 		= 6'b110100;  
parameter len4_bm 		= 6'b110101;  
parameter result1_bm 		= 6'b110110;  
parameter result2_bm 		= 6'b110111;  
parameter result3_bm 		= 6'b111000;  
parameter result4_bm 		= 6'b111001;  
parameter message1_bm 		= 6'b111010;  
parameter message2_bm 		= 6'b111011;  
parameter message3_bm 		= 6'b111100;  
parameter message4_bm 		= 6'b111101;  
parameter write_crc_bm_ctrl_initial	= 6'b111110;  
parameter write_crc_bm_seed		= 6'b111111;  
parameter write_crc_bm_ctrl_second	= 7'b1000000;  
parameter write_crc_bm_poly		= 7'b1000001;  
parameter code_for_bm_2		= 7'b1000010;  
parameter SID_bm_2		= 7'b1000011;  
parameter addr1_bm_2		= 7'b1000100;  
parameter addr2_bm_2		= 7'b1000101;  
parameter addr3_bm_2		= 7'b1000110;  
parameter addr4_bm_2		= 7'b1000111;  
parameter len_bm_2		= 7'b1001000; 
parameter bcle_code    	= 7'd73;   
parameter bcle_sourceid	= 7'd74;	
parameter crc_fd_st_1		= 7'd75;   
parameter crc_fd_st_2		= 7'd76;   
parameter crc_fd_st_3		= 7'd77;   
parameter crc_fd_st_4		= 7'd78;   
parameter BM_crc_check		= 7'd79; 
parameter BM_send_result1		= 7'd80;
parameter BM_send_result2		= 7'd81;
parameter BM_send_result3		= 7'd82;
parameter BM_send_result4		= 7'd83;
parameter BM_send_result5		= 7'd84;
parameter BM_send_result6		= 7'd85;
parameter BM_send_len		= 7'd86;
parameter BM_send_crc_check1	= 7'd87;
parameter BM_send_crc_check2	= 7'd88;
parameter BM_send_crc_check3	= 7'd89;
parameter BM_send_crc_check4	= 7'd90;
parameter BM_check_link		= 7'd91;
parameter BM_message_code		= 7'd92;
parameter BM_send_message_1	= 7'd93;
parameter BM_send_message_2	= 7'd94;
parameter BM_send_message_3	= 7'd95;
parameter BM_send_message_4	= 7'd96;
parameter send_data_state		= 7'd108;



always @(*)
begin
      case(pstate2)
            IDLE_2:
            begin
	   
                    if(start_chain!=0)
                    begin
		
                            n.CmdR  	= 1;

                            n.DataR 	= 8'h00;
                            nstate2 	= BM_check_link;
                    end
                    else
                    begin
                            bm_mode = 0;
                            if(!empty) read_en = 1;
                            else read_en = 0;
	    
                            c.RW		= 0; 
                            c.Sel		= 0;

                            n.CmdR = 1;
                            n.DataR = 0;

                            ctrl_command2  = Data_F_Out[87:80];		
                            source_id2 = Data_F_Out[79:72];
                            address_noc2 = Data_F_Out[71:40];
                            length_field_A	= Data_F_Out[39:32];
                            Wr_Data2 = Data_F_Out[31:0];
	    
                            if(ctrl_command2[7:5] == 3'b001 && empty == 0) nstate2 = READ_ST2_1;
                            else if	(ctrl_command2[7:5] == 3'b011 && empty == 0) nstate2 = WRITE_ST2;
                            else nstate2 = IDLE_2;

	    	
                    end
	    
            end
            
            BM_check_link:
            begin
                    if((flag==0)?chain : Link_reg !=0) begin
                                nstate2	= code_for_bm;
                    end
                    else  if((flag==0)?chain : Link_reg ==0) begin
                                start_chain	= 0;
                                nstate2	= IDLE_2;
                    end
	
            end

            code_for_bm:
            begin
                        bm_mode 	= 1;

                        n.CmdR 		= 1;
                        n.DataR = 8'h23;

                        nstate2  	= SID_bm;
            end

            SID_bm:
            begin
                        n.CmdR		= 0;
                        n.DataR		= 8'h01;

                        nstate2	= addr1_bm;
            end

            addr1_bm:
            begin
                        n.DataR		= (flag==0)?chain[7:0] : Link_reg[7:0];

                        nstate2	= addr2_bm;
            end

            addr2_bm:
            begin
                        n.DataR		= (flag==0)?chain[15:8] : Link_reg[15:8];

                        nstate2	= addr3_bm;
            end

            addr3_bm:
            begin
                        n.DataR		= (flag==0)?chain[23:16] : Link_reg[23:16];

                        nstate2	= addr4_bm;
            end

            addr4_bm:
            begin
                        n.DataR		= (flag==0)?chain[31:24] : Link_reg[31:24];

                        nstate2	= len_bm;
            end

            len_bm:
            begin
                        n.DataR		= 8'h20;

                        nstate2	= SID_rd_bm;
            end

            SID_rd_bm:
            begin
                        n.CmdR		= 1;
                        n.DataR		= 8'h00;

                        if(DataW_reg == 8'h01)
                        begin
                                nstate2	= link1_bm;
                        end
                        else
                        begin
                                nstate2	= SID_rd_bm;
                        end
            end

            link1_bm:
            begin
                        Link_reg[7:0]	= DataW_reg;

                        nstate2	= link2_bm;
            end

            link2_bm:
            begin
                        Link_reg[15:8]	= DataW_reg;

                        nstate2	= link3_bm;
            end

            link3_bm:
            begin
                        Link_reg[23:16]	= DataW_reg;

                        nstate2	= link4_bm;
            end

            link4_bm:
            begin
                        Link_reg[31:24]	= DataW_reg;
                        flag	= 1;
                        nstate2	= seed1_bm;
            end

            seed1_bm:
            begin
                        Seed_reg[7:0]	= DataW_reg;

                        nstate2	= seed2_bm;
            end

            seed2_bm:
            begin
                        Seed_reg[15:8]	= DataW_reg;

                        nstate2	= seed3_bm;
            end

            seed3_bm:
            begin
                        Seed_reg[23:16]	= DataW_reg;

                        nstate2	= seed4_bm;
            end

            seed4_bm:
            begin
                        Seed_reg[31:24]	= DataW_reg;

                        nstate2	= ctrl1_bm;
            end

            ctrl1_bm:
            begin
                        Control_reg[7:0]	= DataW_reg;

                        nstate2	= ctrl2_bm;
            end

            ctrl2_bm:
            begin
                        Control_reg[15:8]	= DataW_reg;

                        nstate2	= ctrl3_bm;
            end

            ctrl3_bm:
            begin
                        Control_reg[23:16]	= DataW_reg;

                        nstate2	= ctrl4_bm;
            end

            ctrl4_bm:
            begin
                        Control_reg[31:24]	= DataW_reg;

                        nstate2	= poly1_bm;
            end

            poly1_bm:
            begin
                        Poly_reg[7:0]	= DataW_reg;

                        nstate2	= poly2_bm;
            end

            poly2_bm:
            begin
                        Poly_reg[15:8]	= DataW_reg;

                        nstate2	= poly3_bm;
            end

            poly3_bm:
            begin
                        Poly_reg[23:16]	= DataW_reg;

                        nstate2	= poly4_bm;
            end

            poly4_bm:
            begin
                        Poly_reg[31:24]	= DataW_reg;

                        nstate2	= data1_bm;
            end

            data1_bm:
            begin
                        Data_for_bm[7:0]	= DataW_reg;

                        nstate2	= data2_bm;
            end

            data2_bm:
            begin
                        Data_for_bm[15:8]	= DataW_reg;

                        nstate2	= data3_bm;
            end

	data3_bm:
	  begin
	    Data_for_bm[23:16]	= DataW_reg;

	    nstate2	= data4_bm;
	  end

	data4_bm:
	  begin
	    Data_for_bm[31:24]	= DataW_reg;

	    nstate2	= len1_bm;
	  end

	len1_bm:
	  begin
	    Length_reg[7:0]		= DataW_reg;

	    nstate2	= len2_bm;
	  end

	len2_bm:
	  begin
	    Length_reg[15:8]	= DataW_reg;

	    nstate2	= len3_bm;
	  end

	len3_bm:
	  begin
	    Length_reg[23:16]	= DataW_reg;

	    nstate2	= len4_bm;
	  end

	len4_bm:
	  begin
	    Length_reg[31:24]	= DataW_reg;

	    nstate2	= result1_bm;
	    //nstate2	= IDLE_2;
	  end

	result1_bm:
	  begin
	    Result_reg[7:0]	= DataW_reg;

	    nstate2	= result2_bm;
	  end

	result2_bm:
	  begin
	    Result_reg[15:8]	= DataW_reg;

	    nstate2	= result3_bm;
	  end

	result3_bm:
	  begin
	    Result_reg[23:16]	= DataW_reg;

	    nstate2	= result4_bm;
	  end

	result4_bm:
	  begin
	    Result_reg[31:24]	= DataW_reg;

	    nstate2	= message1_bm;
	  end

	message1_bm:
	  begin
	    Message_reg[7:0]	= DataW_reg;

	    nstate2	= message2_bm;
	  end

	message2_bm:
	  begin
	    Message_reg[15:8]	= DataW_reg;

	    nstate2	= message3_bm;
	  end

	message3_bm:
	  begin
	    Message_reg[23:16]	= DataW_reg;

	    nstate2	= message4_bm;
	  end

	message4_bm:
	  begin
	    Message_reg[31:24]	= DataW_reg;

	    nstate2	= write_crc_bm_ctrl_initial;
	  end

	write_crc_bm_ctrl_initial:
	  begin
	    c.addr		= 32'h4003_2008;
	    c.Sel		= 1;
	    c.RW		= 1;
	    c.data_wr		= (Control_reg | 32'h0200_0000);
	    
	    nstate2	= write_crc_bm_seed;
	  end

	write_crc_bm_seed:
	  begin
	    c.addr		= 32'h4003_2000;
	    c.data_wr		= Seed_reg;

	    nstate2	= write_crc_bm_ctrl_second;
	  end

	write_crc_bm_ctrl_second:
	  begin
	    c.addr		= 32'h4003_2008;
	    c.data_wr		= Control_reg & 32'hfdff_ffff;

	    nstate2	= write_crc_bm_poly;
	  end

	write_crc_bm_poly:
	  begin
	    c.addr		= 32'h4003_2004;
	    c.data_wr		= Poly_reg;

	    nstate2	= code_for_bm_2;
	    
	  end


	code_for_bm_2:
	  begin
	    n.CmdR		= 1;
	    n.DataR		= 8'h23;

	    c.Sel		= 0;
	    c.RW		= 0;

	    
	   
	     
	    nstate2	= SID_bm_2;
	  end	

	SID_bm_2:
	  begin
	    n.CmdR		= 0;
	    n.DataR		= 8'h01;

	    nstate2	= addr1_bm_2;
	  end


	addr1_bm_2:
	begin
	    n.CmdR		= 0;
	    n.DataR		= Data_for_bm[7:0];

	    nstate2	= addr2_bm_2;
	end

	addr2_bm_2:
	  begin
	    n.DataR		= Data_for_bm[15:8];

	    nstate2	= addr3_bm_2;
	  end

	addr3_bm_2:
	  begin
	    n.DataR		= Data_for_bm[23:16];

	    nstate2	= addr4_bm_2;
	  end

	addr4_bm_2:
	  begin
	    n.DataR		= Data_for_bm[31:24];

	    nstate2	= len_bm_2;
	  end

	len_bm_2:
	  begin
	    if(Length_reg_fl>8'h80)
	      begin
		crc_counter	= 8'h80;
	
		n.DataR      	= 8'h80;
	      end
	    else
	      begin
	        crc_counter	= Length_reg_fl;
	        n.DataR		= Length_reg_fl;
	      end

	    nstate2	= bcle_code;
	  end

	bcle_code: 
	  begin
	    n.CmdR		= 1;
	    n.DataR		= 8'h00;
	    nstate2	= bcle_sourceid;
	  end

	bcle_sourceid:
	  begin
	    nstate2    	= crc_fd_st_1;
	  end

	crc_fd_st_1:
	  begin
	    n.CmdR = 1;
	    n.DataR = 8'h0;

	    c.Sel		= 0;
	    c.RW		= 0;

	    crc_write[7:0]	= DataW_reg; 
	    nstate2	= crc_fd_st_2; 
	  end

	crc_fd_st_2:
	  begin
	    n.CmdR = 1;
	    n.DataR = 8'h0;

	    crc_write[15:8]	= DataW_reg; 
	    nstate2	= crc_fd_st_3; 
	  end

	crc_fd_st_3:
	  begin
	    n.CmdR = 1;
	    n.DataR = 8'h0;

	    crc_write[23:16]	= DataW_reg; 
	    nstate2	= crc_fd_st_4; 
	  end

	crc_fd_st_4:
	  begin
	    n.CmdR = 1;
	    n.DataR = 8'h0;
	    flag2 = 1;

	    c.Sel		= 1;
	    c.RW		= 1;

	    crc_write[31:24]	= DataW_reg;

	    c.addr		= 32'h4003_2000;
	    c.data_wr		= crc_write;	

	    crc_counter		= crc_counter_fl - 8'h04;
	    Length_reg		= Length_reg_fl - 8'h04;

	    if(Length_reg != 32'h0)
	      begin
	        if(crc_counter !=0)
	          begin
		    nstate2	= crc_fd_st_1;
	          end
	        else if(crc_counter ==0)
	          begin
		     Data_for_bm = Data_reg_fl + 8'h80;
		    nstate2	= code_for_bm_2;
	          end
	      end
	    else if(Length_reg == 32'h0)
	      begin
		nstate2		= BM_crc_check;
	      end
	  end

	BM_crc_check:
	  begin
	    c.Sel 			= 1;
	    c.RW 			= 0;
	    c.addr			= 32'h4003_2000;

	    crc_check 			= c.data_rd;

	    nstate2		= BM_send_result1;
	  end

	BM_send_result1:
	  begin
	    c.Sel			= 0;
     	    c.RW			= 0;

	    n.CmdR			= 1;
	    n.DataR			= 8'h63;

	    nstate2		= BM_send_result2;
	  end

	BM_send_result2:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= 8'h01;

	    nstate2	= BM_send_result3;
	  end

	BM_send_result3:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Result_reg[7:0];

	    nstate2	= BM_send_result4;
	  end

	BM_send_result4:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Result_reg[15:8];

	    nstate2	= BM_send_result5;
	  end

	BM_send_result5:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Result_reg[23:16];

	    nstate2	= BM_send_result6;
       	  end

	BM_send_result6:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Result_reg[31:24];

	    nstate2		= BM_send_len;
       	  end

	BM_send_len:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= 8'h04; 

	    nstate2	= BM_send_crc_check1;
       	  end

	BM_send_crc_check1:	
	  begin
	    n.CmdR			= 0;
	    n.DataR			= crc_check[7:0];

	    nstate2		= BM_send_crc_check2;
       	  end

	BM_send_crc_check2:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= crc_check[15:8];

	    nstate2		= BM_send_crc_check3;
       	  end

	BM_send_crc_check3:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= crc_check[23:16]; 

	    nstate2		= BM_send_crc_check4;
       	  end

	BM_send_crc_check4:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= crc_check[31:24]; 

	    //nstate2		= IDLE_2;
	    nstate2		= BM_message_code;
       	  end

	BM_message_code:
	  begin
	    n.CmdR			= 1;
	    n.DataR			= 8'hc4;

	    nstate2		= BM_send_message_1;
	  end

	BM_send_message_1:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Message_reg[7:0];

	    nstate2		= BM_send_message_2;
	  end

	BM_send_message_2:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Message_reg[15:8];

	    nstate2		= BM_send_message_3;
	  end

	BM_send_message_3:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Message_reg[23:16];

	    nstate2		= BM_send_message_4;
	  end

	BM_send_message_4:
	  begin
	    n.CmdR			= 0;
	    n.DataR			= Message_reg[31:24];

	    nstate2		= IDLE_2;
	  end




	READ_ST2_1:
	  begin
	    read_en			= 0;
	    c.RW		= 0;
	    c.Sel		= 1;
	    c.addr 		= address_noc_fl;
	    tmp1		= c.data_rd;

	   
	    if (length_field_A == 8'h04)	nstate2 = ReadResponse_code;
	    else
	      begin
		address_noc2		= address_noc_fl + 4;
	 	nstate2 	= READ_ST2_2;
	      end
	  end

	READ_ST2_2:
	  begin
	    c.addr		= address_noc_fl;
	    tmp2		= c.data_rd;

	   
	    if (length_field_A == 8'h08)	nstate2 = ReadResponse_code;
	    else
	      begin
		address_noc2		= address_noc_fl + 4;
		nstate2	= READ_ST2_3;
	      end
	  end

	READ_ST2_3:
	  begin
	    c.addr		= address_noc_fl;
	    tmp3		= c.data_rd;
	
	    nstate2	= ReadResponse_code;
	  end


	ReadResponse_code:
	  begin
	    c.Sel 	 	= 1'b0; 

	    n.CmdR  		= 1'b1;
	    n.DataR 		= 8'h40;
  
   	    nstate2 	= ReadResponse_returnid;
	  end

	ReadResponse_returnid:
	  begin
	    n.CmdR 		= 1'b0;
	    n.DataR		= return_id2;
	
	    nstate2	= ReadResponse_tmp1_data1;
	  end

	ReadResponse_tmp1_data1:
	  begin
	  
	    n.DataR		= tmp1[7:0];

	    nstate2	= ReadResponse_tmp1_data2;
	  end

	ReadResponse_tmp1_data2:
	  begin

	    n.DataR		= tmp1[15:8];

	    nstate2	= ReadResponse_tmp1_data3;
	  end

	ReadResponse_tmp1_data3:	
	  begin
	 
	    n.DataR		= tmp1[23:16];

	    nstate2	= ReadResponse_tmp1_data4;
	  end

	ReadResponse_tmp1_data4:	
	  begin
	   
	    n.DataR		= tmp1[31:24];

	    if(length_field_A == 8'h04)  nstate2 =  END;
	    else
	      begin
		nstate2	= ReadResponse_tmp2_data1;
	      end
	  end

	ReadResponse_tmp2_data1:
	  begin
	 
	    n.DataR		= tmp2[7:0];

	    nstate2	= ReadResponse_tmp2_data2;
	  end

	ReadResponse_tmp2_data2:
	  begin
	  
	    n.DataR		= tmp2[15:8];

	    nstate2	= ReadResponse_tmp2_data3;
	  end

	ReadResponse_tmp2_data3:
	  begin
	  
	    n.DataR		= tmp2[23:16];

	    nstate2	= ReadResponse_tmp2_data4;
	  end

	ReadResponse_tmp2_data4:
	  begin
	 
	    n.DataR		= tmp2[31:24];

	    if(length_field_A == 8'h08)  nstate2 =  END;
	    else
	      begin
		nstate2	= ReadResponse_tmp3_data1;
	      end
	  end

	ReadResponse_tmp3_data1:
	  begin
	  
	    n.DataR		= tmp3[7:0];

	    nstate2	= ReadResponse_tmp3_data2;
	  end

	ReadResponse_tmp3_data2:
	  begin
	   
	    n.DataR		= tmp3[15:8];

	    nstate2	= ReadResponse_tmp3_data3;
	  end

	ReadResponse_tmp3_data3:
	  begin
	    
	    n.DataR		= tmp3[23:16];

	    nstate2	= ReadResponse_tmp3_data4;
	  end

	ReadResponse_tmp3_data4:
	  begin
	   
	    n.DataR		= tmp3[31:24];

	   
	    nstate2	= END;
	  end

	END:   
	  begin
	    //c.Sel		= 0; 
	    n.CmdR		= 1'b1;
	    n.DataR		= 8'b11100000;    //=E0

	    nstate2	= IDLE_2;
	  end

	WRITE_ST2:
  	  begin
	    read_en		   = 0; 
	    c.addr	   = address_noc_fl;
	    c.RW	   = 1;
	    c.Sel	   = 1;
	    c.data_wr	   = Wr_Data2;

	    nstate2   = WriteResponse_code;
	  end

	WriteResponse_code:
	  begin
	    c.Sel	   	= 0;
	    c.RW 	   	= 0;

	    n.CmdR  		= 1'b1;
	    n.DataR 		= 8'h80;

	    nstate2	= WriteResponse_returnid;
	  end

	WriteResponse_returnid:
	  begin
	    n.CmdR 		= 1'b0;
	    n.DataR		= return_id2;
	
	    nstate2	= IDLE_2;
	  end

      endcase
    end

endmodule : noc 

//.......... Memory for fifo............
module mem32x64(input bit clk,input logic [11:0] waddr,
    input logic [99:0] wdata, input bit write,
    input logic [11:0] raddr, output logic [99:0] rdata);

logic [99:0] mem[0:4096];

logic [99:0] rdatax;

logic [99:0] w0,w1,w2,w3,w4,w5,w6,w7;

assign rdata = rdatax;

always @(*) begin
  rdatax <= #2 mem[raddr];
end

always @(posedge(clk)) begin
  if(write) begin
    mem[waddr]<=#2 wdata;
  end
end

endmodule : mem32x64


//.............. FIFO .............
   
module fifo(clk, rst, write_en, fifo_in, read_en, fifo_out , full, empty);

input bit clk, rst, write_en, read_en;        
input  logic [99:0] fifo_in;
output logic [99:0] fifo_out;
output bit full, empty;


logic [11:0] W_ptr;
logic [11:0] R_ptr;
logic [11:0] counter;

mem32x64 M1(.clk(clk), .waddr(W_ptr), .wdata(fifo_in), .write(write_en), .raddr(R_ptr), .rdata(fifo_out));

assign full  =  (R_ptr == W_ptr + 1)? 1'b1:1'b0; 
assign empty =   (R_ptr == W_ptr) ? 1'b1:1'b0; 


always @(posedge clk or posedge rst)
begin 

    if (rst) begin 
        W_ptr <= #1 'b0;  
    end 
    else begin 
        if (write_en == 1'b1 && (!full))                   
            W_ptr <= #1 W_ptr + 1'b1;
    end
end 

always @(posedge clk or posedge rst)
begin 

    if (rst) begin 
        R_ptr <= #1 'b0; 
    end 
    else begin 
        if (read_en == 1'b1 && (!empty))                   
            R_ptr <= #1 R_ptr +1'b1;
    end 
end 

always @(posedge clk or posedge rst)
begin 
    if (rst)
        counter <= #1 'b0;   
    else
        if (write_en == 1'b1 && read_en == 1'b0 && (!full))
            counter <= #1 (counter + 1);        
    else
        if (write_en == 1'b0 && read_en == 1'b1 && (!empty))               
            counter <= #1 (counter - 1);
end 


endmodule : fifo


