`timescale 1ns / 1ps

module CPUtop(clk, rst, instruction_in, data_in, data_out, instruction_address, data_address, data_R, data_W, done);
    
    input clk;
    input rst;
    input [17:0] instruction_in;
    input [15:0] data_in;
    output [15:0] data_out;
    output [9:0] instruction_address;
    output [9:0] data_address;
    output data_R;
    output data_W;
    output done;
    wire [5:0] opcode = instruction_in[17:12];
    
    parameter [2:0] STATE_IDLE = 0;
    parameter [2:0] STATE_IF = 1;
    parameter [2:0] STATE_ID = 2;
    parameter [2:0] STATE_EX = 3;
    parameter [2:0] STATE_MEM = 4;
    parameter [2:0] STATE_WB = 5;
    parameter [2:0] STATE_HALT = 6;
    
    reg [2:0] current_state;
    reg [9:0] PC,next_PC;
    reg [9:0] current_data_address;
    reg rdata_en;
    reg wdata_en;
    reg [15:0] data_out_reg;
    
    assign data_out = data_out_reg;
    assign data_R = rdata_en;
    assign data_W = wdata_en;
    assign data_address = current_data_address;
    
    reg [15:0] H[0:3];
    reg [15:0] Oset[0:2];
    reg [15:0] Qset[0:2];
    reg [9:0]  LC;
    reg [9:0] im_reg;
    
    reg CMD_addition;
    reg CMD_multiplication;
    reg CMD_substruction;
    reg CMD_mul_accumulation;
    reg CMD_logic_shift_right;
    reg CMD_logic_shift_left;
    reg CMD_and;
    reg CMD_or;
    reg CMD_not;
    reg CMD_load;
    reg CMD_store;
    reg CMD_set;
    reg CMD_loopjump;
    reg CMD_setloop;
    reg Hreg1;
    reg Hreg2;
    reg Hreg3;
    reg Him;
    reg Oreg1;
    reg Oreg2;
    reg Oreg3;
    reg Oim;
    reg Qreg1;
    reg Qreg2;
    reg Qreg3;
    reg Qim;
    reg [15:0] result_reg_add;
    reg [15:0] result_reg_sub;
    reg [15:0] result_reg_mul;
    reg [15:0] result_reg_mac;
    reg [15:0] result_reg_Lshift;
    reg [15:0] result_reg_Rshift;
    reg [15:0] result_reg_and;
    reg [15:0] result_reg_or;
    reg [15:0] result_reg_not;
    reg [15:0] result_reg_load;
    reg [15:0] result_reg_store;
    reg [15:0] result_reg_set;
    reg [1:0] R0;
    reg [1:0] R1;
    reg [1:0] R2;
    reg [1:0] R3;
    
    wire [15:0] comp_input_A = Hreg1?(H[R0]):((Hreg2|Hreg3)?(H[R2]):(Oreg1?(Oset[R0]):((Oreg2|Oreg3)?(Oset[R2]):(Qreg1?(Qset[R0]):((Qset[R2]))))));
    wire [15:0] comp_input_B = Hreg1?(im_reg):((Hreg2|Hreg3)?(H[R3]):(Oreg1?({im_reg[7:0],im_reg[7:0]}):((Oreg2|Oreg3)?(Oset[R3]):(Qreg1?({im_reg[3:0],im_reg[3:0],im_reg[3:0],im_reg[3:0]}):((Qset[R3]))))));
    
    wire [15:0] Add_output_Cout;
    wire [15:0] Mul_output_Cout;
    wire [15:0] MAC_output_Cout;
    
    wire [15:0] MAC_input_A = Hreg3?(H[R1]):(Oreg3?(Oset[R1]):(Qset[R1]));
    wire [15:0] MAC_input_B = Mul_output_Cout;
    
    SIMDadd Add(
            .A(CMD_mul_accumulation?MAC_input_A:comp_input_A),
            .B(CMD_mul_accumulation?MAC_input_B:comp_input_B),
            .H(Hreg1|Hreg2|Hreg3),
            .O(Oreg1|Oreg2|Oreg3),
            .Q(Qreg1|Qreg2|Qreg3),
            .sub(CMD_substruction),
            .Cout(Add_output_Cout)
        );
        
    wire [15:0] shiftinput = Hreg1?(H[R3]):(Oreg1?(Oset[R3]):(Qset[R3]));
    wire [15:0] shiftoutput;
        
    SIMDshifter shift(
                .shiftinput(shiftinput),
                .H(Hreg1),
                .O(Oreg1),
                .Q(Qreg1),
                .left(CMD_logic_shift_left),
                .shiftoutput(shiftoutput)
            );
     
    SIMDmultiply Mul(
                .mulinputa(comp_input_A),
                .mulinputb(comp_input_B),
                .H(Hreg1|Hreg2|Hreg3),
                .O(Oreg1|Oreg2|Oreg3),
                .Q(Qreg1|Qreg2|Qreg3),
                .muloutput(Mul_output_Cout)
                );
                

    assign instruction_address = PC; 
    assign done = current_state == STATE_HALT;
    
    always @(posedge clk)
    begin
        if (rst) 
        begin
            current_state <= STATE_IDLE;
            PC <= 0;
        end
        else
        begin
            if (opcode == 63) current_state <= STATE_HALT;
            else
            if (current_state == STATE_IDLE)
            begin
                current_state <= STATE_IF;
            end
            else if (current_state == STATE_IF)
            begin
                $display("======== another instruction ========");
                $display("H00: %b",H[0]);
                $display("H01: %b",H[1]);
                $display("H10: %b",H[2]);
                $display("H11: %b",H[3]);
                $display("Oset00: %b",Oset[0]);
                $display("Oset01: %b",Oset[1]);
                $display("Oset10: %b",Oset[2]);
                $display("Qset00: %b",Qset[0]);
                $display("Qset01: %b",Qset[1]);
                $display("Qset10: %b",Qset[2]);
                $display("           -- execute --             ");
                current_state <= STATE_ID;
            end
            else if (current_state == STATE_ID)
            begin
                current_state <= STATE_EX;
            end
            else if (current_state == STATE_EX)
            begin
                current_state <= STATE_MEM;
            end
            else if (current_state == STATE_MEM)
            begin
                current_state <= STATE_WB;
            end
            else if (current_state == STATE_WB)
            begin
                current_state <= STATE_IF;
                PC <= next_PC;
            end
        end
    end    
    
    always @(posedge clk)
    begin
        if (rst) 
        begin
                     
        end
        else
        begin
            
        end
    end    
    
    
    always @(posedge clk)
    begin
        if (rst || current_state == STATE_IDLE || current_state == STATE_IF) 
        begin
            CMD_addition <= 0;
            CMD_multiplication <= 0;
            CMD_substruction <= 0;
            CMD_mul_accumulation <= 0;
            CMD_logic_shift_right <= 0;
            CMD_logic_shift_left <= 0;
            CMD_and <= 0;
            CMD_or <= 0;
            CMD_not <= 0;
            CMD_load <= 0;
            CMD_store <= 0;
            CMD_set <= 0;
            CMD_loopjump <= 0;
            CMD_setloop <= 0;
            Hreg1<=0;
            Hreg2<=0;
            Hreg3<=0;
            Him<=0;
            Oreg1<=0;
            Oreg2<=0;
            Oreg3<=0;
            Oim<=0;
            Qreg1<=0;
            Qreg2<=0;
            Qreg3<=0;
            Qim<=0;
            im_reg <= 10'b0000000000;
            R0 <= 0;
            R1 <= 0;
            R2 <= 0;
            R3 <= 0;
        end
        else
        begin
            if (current_state == STATE_ID)
            begin
                CMD_addition <= (opcode<=5);
                CMD_substruction <= (opcode>=6)&&(opcode<=11);
                CMD_multiplication <= (opcode>=12)&&(opcode<=17);                
                CMD_mul_accumulation <= (opcode>=18)&&(opcode<=20);
                CMD_logic_shift_left <= (opcode>=21)&&(opcode<=23);
                CMD_logic_shift_right <= (opcode>=24)&&(opcode<=26);
                CMD_and <= (opcode>=27)&&(opcode<=29);
                CMD_or <= (opcode>=30)&&(opcode<=32);
                CMD_not <= (opcode>=33)&&(opcode<=35);
                CMD_loopjump <= opcode==36;
                CMD_setloop <= opcode==37;
                CMD_load <= (opcode>=38)&&(opcode<=40);
                CMD_store <= (opcode>=41)&&(opcode<=43);
                CMD_set <= (opcode>=44)&&(opcode<=46);     
                Hreg1<=(opcode==3)||(opcode==9)||(opcode==15)||(opcode==21)||(opcode==24)||(opcode==33)||(opcode==38)||(opcode==41)||(opcode==44);
                Hreg2<=(opcode==0)||(opcode==6)||(opcode==12)||(opcode==27)||(opcode==30);
                Hreg3<=(opcode==18);
                Him<=(opcode==3)||(opcode==9)||(opcode==15)||(opcode==38)||(opcode==41)||(opcode==44);
                
                Oreg1<=(opcode==4)||(opcode==10)||(opcode==16)||(opcode==22)||(opcode==25)||(opcode==34)||(opcode==39)||(opcode==42)||(opcode==45);
                Oreg2<=(opcode==1)||(opcode==7)||(opcode==13)||(opcode==28)||(opcode==31);
                Oreg3<=(opcode==19);
                Oim<=(opcode==4)||(opcode==10)||(opcode==16)||(opcode==39)||(opcode==42)||(opcode==45);
                
                Qreg1<=(opcode==5)||(opcode==11)||(opcode==17)||(opcode==23)||(opcode==26)||(opcode==35)||(opcode==40)||(opcode==43)||(opcode==46);
                Qreg2<=(opcode==2)||(opcode==8)||(opcode==14)||(opcode==29)||(opcode==32);
                Qreg3<=(opcode==20);
                Qim<=(opcode==5)||(opcode==11)||(opcode==17)||(opcode==40)||(opcode==43)||(opcode==46);
                
                im_reg <= instruction_in[9:0];
                R0 <= instruction_in[11:10];
                R1 <= instruction_in[5:4];
                R2 <= instruction_in[3:2];
                R3 <= instruction_in[1:0];
                $display("PC: %0d : instruction = %b", PC,instruction_in);
            end            
        end
    end    
    
    always @(posedge clk)
    begin
        if (rst || current_state == STATE_IDLE || current_state == STATE_IF) 
        begin
            result_reg_add <= 0;
            result_reg_sub <= 0;
            result_reg_mul <= 0;
            result_reg_mac <= 0;
            result_reg_Lshift <= 0;
            result_reg_Rshift <= 0;
            result_reg_and <= 0;
            result_reg_or <= 0;
            result_reg_not <= 0;
            result_reg_set <= 0;
            current_data_address <= 0;
            rdata_en <= 0;
            wdata_en <= 0;
            if (rst)
            begin
                next_PC <= 0;
            end
        end
        
        else if (current_state == STATE_EX)
        begin
        
            if (CMD_addition) 
            begin
                result_reg_add <= Add_output_Cout;
                if (Hreg2) 
                begin
                    $display("add16bit R%d=%b R%d=%b", R2,H[R2],R3,H[R3]);
                end
                else if (Oreg2) 
                begin
                    $display("add8bit R%d=%b R%d=%b", R2,Oset[R2],R3,Oset[R3]);
                end
                else if (Qreg2) 
                begin
                    $display("add4bit R%d=%b R%d=%b", R2,Qset[R2],R3,Qset[R3]);
                end 
                else if (Him)
                begin
                    $display("add16bit R%d=%b im=%b", R0,H[R0],im_reg);
                end
                else if (Oim)
                begin
                    $display("add8bit R%d=%b im=%b", R0,Oset[R0],im_reg);
                end
                else if (Qim)
                begin
                    $display("add4bit R%d=%b im=%b", R0,Qset[R0],im_reg);
                end
            end 
            
            else if (CMD_substruction) 
            begin
                result_reg_sub <= Add_output_Cout;
                if (Hreg2) 
                begin
                    $display("sub16bit R%d=%b R%d=%b", R2,H[R2],R3,H[R3]);
                end
                else if (Oreg2) 
                begin
                    $display("sub8bit R%d=%b R%d=%b", R2,Oset[R2],R3,Oset[R3]);
                end
                else if (Qreg2) 
                begin
                    $display("sub4bit R%d=%b R%d=%b", R2,Qset[R2],R3,Qset[R3]);
                end
                else if (Him)
                begin
                    $display("sub16bit R%d=%b im=%b", R0,H[R0],im_reg);
                end
                else if (Oim)
                begin
                    $display("sub8bit R%d=%b im=%b", R0,Oset[R0],im_reg);
                end
                else if (Qim)
                begin
                    $display("sub4bit R%d=%b im=%b", R0,Qset[R0],im_reg);
                end
            end        
        
            else if (CMD_multiplication) 
            begin
                result_reg_mul<=Mul_output_Cout;
                if (Hreg2) 
                begin
                    $display("mul16bit R%d=%b R%d=%b", R2,H[R2],R3,H[R3]);
                end
                else if (Oreg2) 
                begin
                    $display("mul8bit R%d=%b R%d=%b", R2,Oset[R2],R3,Oset[R3]);
                end
                else if (Qreg2) 
                begin
                    $display("mul4bit R%d=%b R%d=%b", R2,Qset[R2],R3,Qset[R3]);
                end
                else if (Him)
                begin
                    $display("mul16bit R%d=%b im=%b", R0,H[R0],im_reg);
                end
                else if (Oim)
                begin
                    $display("mul8bit R%d=%b im=%b", R0,Oset[R0],im_reg);
                end
                else if (Qim)
                begin
                    $display("mul4bit R%d=%b im=%b", R0,Qset[R0],im_reg);
                end
            end
            
            else if (CMD_mul_accumulation) 
            begin
                result_reg_mac <= Add_output_Cout;
                if (Hreg3) 
                begin
                    $display("MAC16bit R%d=%b R%d=%b R%d=%b", R1,H[R1],R2,H[R2],R3,H[R3]);
                end
                else if (Oreg3) 
                begin
                    $display("MAC8bit R%d=%b R%d=%b R%d=%b", R1,Oset[R1],R2,Oset[R2],R3,Oset[R3]);
                end
                else if (Qreg3) 
                begin
                    $display("MAC4bit R%d=%b R%d=%b R%d=%b", R1,Qset[R1],R2,Qset[R2],R3,Qset[R3]);
                end
            end
            
            else if (CMD_logic_shift_right) 
            begin
                result_reg_Rshift <= shiftoutput;
                if (Hreg1) 
                begin
                    $display("Rshift16bit R%d=%b", R3,H[R3]);
                end
                else if (Oreg1) 
                begin
                    $display("Rshift8bit R%d=%b", R3,Oset[R3]);
                end
                else if (Qreg1) 
                begin
                    $display("Rshift4bit R%d=%b", R3,Qset[R3]);
                end
            end
            
            else if (CMD_logic_shift_left) 
            begin
                result_reg_Lshift <= shiftoutput;
                if (Hreg1) 
                begin
                    $display("Lshift16bit R%d=%b", R3,H[R3]);
                end
                else if (Oreg1) 
                begin
                    $display("Lshift8bit R%d=%b", R3,Oset[R3]);
                end
                else if (Qreg1) 
                begin
                    $display("Lshift4bit R%d=%b", R3,Qset[R3]);
                end
            end
            
            else if (CMD_and) 
            begin
                if (Hreg2) 
                begin
                    result_reg_and <= H[R2] & H[R3];
                    $display("and16bit R%d=%b R%d=%b", R2,H[R2],R3,H[R3]);
                end
                else if (Oreg2) 
                begin
                    result_reg_and <= Oset[R2] & Oset[R3];
                    $display("and8bit R%d=%b R%d=%b", R2,Oset[R2],R3,Oset[R3]);
                end
                else if (Qreg2) 
                begin
                    result_reg_and <= Qset[R2] & Qset[R3];
                    $display("and4bit R%d=%b R%d=%b", R2,Qset[R2],R3,Qset[R3]);
                end
            end
            
            else if (CMD_or) 
            begin
                if (Hreg2) 
                begin
                    result_reg_or <= H[R2] | H[R3];
                    $display("or16bit R%d=%b R%d=%b", R2,H[R2],R3,H[R3]);
                end
                else if (Oreg2) 
                begin
                    result_reg_or <= Oset[R2] | Oset[R3];
                    $display("or8bit R%d=%b R%d=%b", R2,Oset[R2],R3,Oset[R3]);
                end
                else if (Qreg2) 
                begin
                    result_reg_or <= Qset[R2] | Qset[R3];
                    $display("or4bit R%d=%b R%d=%b", R2,Qset[R2],R3,Qset[R3]);
                end
            end
    
            
            else if (CMD_not) 
            begin
                if (Hreg1) 
                begin
                    result_reg_not <= ~H[R3];
                    $display("not16bit R%d=%b", R3,H[R3]);
                end
                else if (Oreg1) 
                begin
                    result_reg_not <= ~Oset[R3];
                    $display("not8bit R%d=%b", R3,Oset[R3]);
                end
                else if (Qreg1) 
                begin
                    result_reg_not <= ~Qset[R3];
                    $display("not4bit R%d=%b", R3,Qset[R3]);
                end
            end
            
            else if (CMD_set) 
            begin
                if (Hreg1) 
                begin
                    result_reg_set <= im_reg;
                    $display("set16bit R%d im=%b", R0,im_reg);
                end
                else if (Oreg1) 
                begin
                    result_reg_set[7:0] <= im_reg;
                    result_reg_set[15:8] <= im_reg;
                    $display("set8bit R%d im=%b", R0,im_reg);
                end
                else if (Qreg1) 
                begin
                    result_reg_set[3:0] <= im_reg;
                    result_reg_set[7:4] <= im_reg;
                    result_reg_set[11:8] <= im_reg;
                    result_reg_set[15:12] <= im_reg;
                    $display("set4bit R%d im=%b", R0,im_reg);
                end
            end
            
            else if (CMD_load) 
            begin
                rdata_en <= 1;
                current_data_address <= im_reg;
                if (Hreg1) 
                begin
                    $display("load16bit R%d im=%b", R0,im_reg);
                end
                else if (Oreg1) 
                begin
                    $display("load8bit R%d im=%b", R0,im_reg);
                end
                else if (Qreg1) 
                begin
                    $display("load4bit R%d im=%b", R0,im_reg);
                end 
                
            end
            
            else if (CMD_store) 
            begin
                wdata_en <= 1;
                rdata_en <= 1;
                current_data_address <= im_reg;
                
                if (Hreg1) 
                begin
                    data_out_reg <= H[R0];
                    $display("store16bit R%d=%b im=%b", R0,H[R0],im_reg);
                end
                else if (Oreg1) 
                begin
                    data_out_reg <= Oset[R0];
                    $display("store8bit R%d=%b im=%b", R0,Oset[R0],im_reg);
                end
                else if (Qreg1) 
                begin
                    data_out_reg <= Qset[R0];
                    $display("store4bit R%d=%b im=%b", R0,Qset[R0],im_reg);
                end            
            end
                        
            if (CMD_loopjump)
            begin
                $display("loopjump LC=%d im=%d", LC,im_reg);
                if (LC != 0)
                begin
                    next_PC <= im_reg;
                    LC <= LC - 1;
                end
                else
                begin                    
                    next_PC <= next_PC + 1;
                end
            end
            else 
                next_PC <= next_PC + 1;
                
            if (CMD_setloop)
            begin
                $display("setloop im=%d", im_reg);
                LC <= im_reg;
            end        
        end                    
    end
    
    
    always @(posedge clk)
    begin
        if (rst || current_state == STATE_IDLE || current_state == STATE_IF) 
        begin
        end
        else
        begin
            if (current_state == STATE_MEM)
            begin
                
            end            
        end
    end   
    
    always @(posedge clk)
    begin
        if (rst || current_state == STATE_IDLE || current_state == STATE_IF) 
        begin
        end
        
        else if (current_state == STATE_WB)
        begin
        
            if (CMD_addition) 
            begin
                if (Hreg2) 
                begin
                    H[R2] <= result_reg_add;
                end
                else if (Oreg2) 
                begin
                    Oset[R2] <= result_reg_add;
                end
                else if (Qreg2) 
                begin
                    Qset[R2] <= result_reg_add;
                end 
                else if (Him)
                begin
                    H[R0] <= result_reg_add;
                end
                else if (Oim)
                begin
                    Oset[R0] <= result_reg_add;
                end
                else if (Qim)
                begin
                    Qset[R0] <= result_reg_add;
                end
            end 
            
            else if (CMD_substruction) 
            begin
                if (Hreg2) 
                begin
                    H[R2] <= result_reg_sub;
                end
                else if (Oreg2) 
                begin
                    Oset[R2] <= result_reg_sub;
                end
                else if (Qreg2) 
                begin
                    Qset[R2] <= result_reg_sub;
                end
                else if (Him)
                begin
                    H[R0] <= result_reg_sub;
                end
                else if (Oim)
                begin
                    Oset[R0] <= result_reg_sub;
                end
                else if (Qim)
                begin
                    Qset[R0] <= result_reg_sub;
                end
            end
        end
        
        else if (CMD_multiplication) 
        begin
            if (Hreg2) 
            begin
                H[R2] <= result_reg_mul;
            end
            else if (Oreg2) 
            begin
                Oset[R2] <= result_reg_mul;
            end
            else if (Qreg2) 
            begin
                Qset[R2] <= result_reg_mul;
            end
            else if (Him)
            begin
                H[R0] <= result_reg_mul;
            end
            else if (Oim)
            begin
                Oset[R0] <= result_reg_mul;
            end
            else if (Qim)
            begin
                Qset[R0] <= result_reg_mul;
            end
        end
        
        else if (CMD_mul_accumulation) 
        begin
            if (Hreg3) 
            begin
                H[R1] <= result_reg_mac;
            end
            else if (Oreg3) 
            begin
                Oset[R1] <= result_reg_mac;
            end
            else if (Qreg3) 
            begin
                Qset[R1] <= result_reg_mac;
            end
        end
        
        else if (CMD_logic_shift_right) 
        begin
            if (Hreg1) 
            begin
                H[R3] <= result_reg_Rshift;
            end
            else if (Oreg1) 
            begin
                Oset[R3] <= result_reg_Rshift;
            end
            else if (Qreg1) 
            begin
                Qset[R3] <= result_reg_Rshift;
            end
        end
        
        else if (CMD_logic_shift_left) // do shift left
        begin
            if (Hreg1) 
            begin
                H[R3] <= result_reg_Lshift;
            end
            else if (Oreg1) 
            begin
                Oset[R3] <= result_reg_Lshift;
            end
            else if (Qreg1) 
            begin
                Qset[R3] <= result_reg_Lshift;
            end
        end
        
        else if (CMD_and) // do and
        begin
            if (Hreg2) 
            begin
                H[R2] <= result_reg_and;
            end
            else if (Oreg2) 
            begin
                Oset[R2] <= result_reg_and;
            end
            else if (Qreg2) 
            begin
                Qset[R2] <= result_reg_and;
            end
        end
        
        else if (CMD_or) // do or
        begin
            if (Hreg2) 
            begin
                H[R2] <= result_reg_or;
            end
            else if (Oreg2) 
            begin
                Oset[R2] <= result_reg_or;
            end
            else if (Qreg2) 
            begin
                Qset[R2] <= result_reg_or;
            end
        end

        
        else if (CMD_not) // do not
        begin
            if (Hreg1) 
            begin
                H[R3] <= result_reg_not;
            end
            else if (Oreg1) 
            begin
                Oset[R3] <= result_reg_not;
            end
            else if (Qreg1) 
            begin
                Qset[R3] <= result_reg_not;
            end
        end
        
        else if (CMD_set) // do set
        begin
            if (Hreg1) 
            begin
                H[R0] <= result_reg_set;
            end
            else if (Oreg1) 
            begin
                Oset[R0] <= result_reg_set;
            end
            else if (Qreg1) 
            begin
                Qset[R0] <= result_reg_set;
            end
        end
        else if (CMD_load)
        begin
            if (Hreg1) 
            begin
                H[R0] <= data_in;
            end
            else if (Oreg1) 
            begin
                Oset[R0] <= data_in;
            end
            else if (Qreg1) 
            begin
                Qset[R0] <= data_in;
            end 
        end

    end
    
endmodule



module SIMDmultiply(
        mulinputa,
         mulinputb,
        H,
        O,
        Q,
        muloutput
    );
    

        input [15:0] mulinputa;
        input [15:0] mulinputb;
        input H;
        input O;
        input Q;
        output [15:0] muloutput;
        
    wire [15:0] sel0 = H?16'hFFFF:(O?16'h00FF:16'h000F);
    wire [15:0] sel1 = H?16'hFFFF:(O?16'h00FF:16'h00F0);
    wire [15:0] sel2 = H?16'hFFFF:(O?16'hFF00:16'h0F00);
    wire [15:0] sel3 = H?16'hFFFF:(O?16'hFF00:16'hF000);
    
    wire [15:0] a0 = (mulinputb[0]?mulinputa:16'h0000)&sel0;
    wire [15:0] a1 = (mulinputb[1]?mulinputa:16'h0000)&sel0;
    wire [15:0] a2 = (mulinputb[2]?mulinputa:16'h0000)&sel0;
    wire [15:0] a3 = (mulinputb[3]?mulinputa:16'h0000)&sel0;
    wire [15:0] a4 = (mulinputb[4]?mulinputa:16'h0000)&sel1;
    wire [15:0] a5 = (mulinputb[5]?mulinputa:16'h0000)&sel1;
    wire [15:0] a6 = (mulinputb[6]?mulinputa:16'h0000)&sel1;
    wire [15:0] a7 = (mulinputb[7]?mulinputa:16'h0000)&sel1;
    wire [15:0] a8 = (mulinputb[8]?mulinputa:16'h0000)&sel2;
    wire [15:0] a9 = (mulinputb[9]?mulinputa:16'h0000)&sel2;
    wire [15:0] a10 = (mulinputb[10]?mulinputa:16'h0000)&sel2;
    wire [15:0] a11 = (mulinputb[11]?mulinputa:16'h0000)&sel2;
    wire [15:0] a12 = (mulinputb[12]?mulinputa:16'h0000)&sel3;
    wire [15:0] a13 = (mulinputb[13]?mulinputa:16'h0000)&sel3;
    wire [15:0] a14 = (mulinputb[14]?mulinputa:16'h0000)&sel3;
    wire [15:0] a15 = (mulinputb[15]?mulinputa:16'h0000)&sel3;
    
    wire [15:0] tmp0;
    wire [15:0] tmp1;
    wire [15:0] tmp2;
    wire [15:0] tmp3;
    wire [15:0] tmp00;
    wire [15:0] tmp11;
    wire [15:0] tmp000;
    
    assign tmp0  = a0   + (a1<<1)   +  (a2<<2)    +  (a3<<3);
    assign tmp1  = a4   + (a5<<1)   +  (a6<<2)    +  (a7<<3);
    assign tmp2  = a8   + (a9<<1)   +  (a10<<2)   +  (a11<<3);
    assign tmp3  = a12  + (a13<<1)  +  (a14<<2)   +  (a15<<3);
    
    assign tmp00 = tmp0 + (tmp1<<4);
    assign tmp11 = tmp2 + (tmp3<<4);
   
    assign tmp000 = tmp00 + (tmp11<<8); 
    
    wire [3:0] tmp1h;
    wire [3:0] tmp1o;
    wire [3:0] tmp1q;
    wire [3:0] tmp2h;
    wire [3:0] tmp2o;
    wire [3:0] tmp2q;
    wire [3:0] tmp3h;
    wire [3:0] tmp3o;
    wire [3:0] tmp3q;
    
    assign muloutput[3:0] = tmp0[3:0];
    
    assign tmp1h = tmp000[7:4];    
    assign tmp2h = tmp000[11:8];     
    assign tmp3h = tmp000[15:12];    
    
    assign tmp1o = tmp00[7:4];    
    assign tmp2o = tmp11[11:8];    
    assign tmp3o = tmp11[15:12];
    
    assign tmp1q = tmp1[7:4];    
    assign tmp2q = tmp2[11:8];
    assign tmp3q = tmp3[15:12];
    
    assign muloutput[7:4]   = H?tmp1h:(O?tmp1o:tmp1q);
    assign muloutput[11:8]  = H?tmp2h:(O?tmp2o:tmp2q);
    assign muloutput[15:12] = H?tmp3h:(O?tmp3o:tmp3q);
    
    
endmodule



module SIMDadd(
          A,
          B,
         H,
         O,
         Q,
         sub,
        Cout
    );
            input [15:0] A;
        input [15:0] B;
        input H;
        input O;
        input Q;
        input sub;
        output [15:0] Cout;
    wire [15:0] B_real = sub?(~B):B;
    wire [4:0] C0 = A[3:0]   +  B_real[3:0]    + sub;
    wire [4:0] C1 = A[7:4]   +  B_real[7:4]    + (C0[4]&(O|H)) + (Q&sub);
    wire [4:0] C2 = A[11:8]  +  B_real[11:8]   + (C1[4]&H)     + ((Q|O)&sub);
    wire [4:0] C3 = A[15:12] +  B_real[15:12]  + (C2[4]&(O|H)) + (Q&sub);
    
    assign Cout = {C3[3:0],C2[3:0],C1[3:0],C0[3:0]};
    
    
endmodule




module SIMDshifter(
        shiftinput,
        H,
        O,
        Q,
        left,
        shiftoutput
    );
    
            input [15:0] shiftinput;
        input H;
        input O;
        input Q;
        input left;
        output [15:0] shiftoutput;
    
    wire [14:0] left_shift =  shiftinput[14:0];
    wire [14:0] right_shift =  shiftinput[15:1];
    wire [15:0] shiftoutput_tmp = left?{left_shift,1'b0}:{1'b0,right_shift};
    assign shiftoutput[3:0]   = {(left|H|O)&shiftoutput_tmp[3],   shiftoutput_tmp[2:0]};
    assign shiftoutput[7:4]   = {(left|H)&shiftoutput_tmp[7],     shiftoutput_tmp[6:5],    (!left|H|O)&shiftoutput_tmp[4]};
    assign shiftoutput[11:8]  = {(left|H|O)&shiftoutput_tmp[11],  shiftoutput_tmp[10:9],   (!left|H)&shiftoutput_tmp[8]};
    assign shiftoutput[15:12] = {(left|H)&shiftoutput_tmp[15],    shiftoutput_tmp[14:13],  (!left|H|O)&shiftoutput_tmp[12]};
    
    
    
endmodule
