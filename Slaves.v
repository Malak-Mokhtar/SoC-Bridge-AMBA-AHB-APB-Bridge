module Slaves(PADDR,PWDATA,PSEL,PWRITE,PENABLE,PRDATA);

    parameter WIDTH = 32;
    parameter HEIGHT = 32;
    parameter ADDR = 5;
    parameter SLAVES_NUM = 4;

    input PWRITE,PENABLE;
    input [ADDR-1:0] PADDR;
    input [SLAVES_NUM-1:0] PSEL;
    input [WIDTH-1:0] PWDATA;
    output reg [WIDTH-1:0] PRDATA;

    reg [WIDTH-1:0] slave1 [HEIGHT-1:0];
    reg [WIDTH-1:0] slave2 [HEIGHT-1:0];
    reg [WIDTH-1:0] slave3 [HEIGHT-1:0];
    reg [WIDTH-1:0] slave4 [HEIGHT-1:0];

    initial 
		begin
			$readmemb("memory1.txt",slave1,0,31);
            $readmemb("memory2.txt",slave2,0,31);
            $readmemb("memory3.txt",slave3,0,31);
            $readmemb("memory4.txt",slave4,0,31);
		end

	always @(posedge PENABLE) begin
        case (PSEL)
            4'b0001: begin
                if(PWRITE)
                    slave1[PADDR] <= PWDATA;
                else
                    PRDATA <= slave1[PADDR]; 
            end
            4'b0010: begin
                if(PWRITE)
                    slave2[PADDR] <= PWDATA;
                else
                    PRDATA <= slave2[PADDR]; 
            end
            4'b0100: begin
                if(PWRITE)
                    slave3[PADDR] <= PWDATA;
                else
                    PRDATA <= slave3[PADDR]; 
            end
            4'b1000: begin
                if(PWRITE)
                    slave4[PADDR] <= PWDATA;
                else
                    PRDATA <= slave4[PADDR]; 
            end
            default: begin
                PRDATA <= 0;
            end 
        endcase
    end

endmodule