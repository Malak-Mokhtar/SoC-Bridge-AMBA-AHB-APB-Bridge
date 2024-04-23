module Write_Transfers_tb ();

    // Inputs:
    reg HCLK,RESET_n,HSEL,HWRITE,HREADY;
    reg [6:0] HADDR; // (2 BITS PSEL) + (5 BITS PADDR)
    reg [31:0] HWDATA;
    wire [31:0] PRDATA;

    // Outputs:
    wire HREADYOUT,PENABLE,PWRITE;
    wire [3:0] PSEL; // OUT OF DECODER
    wire [4:0] PADDR;
    wire [31:0] HRDATA,PWDATA;

    
    // Main module instantiation:
    APB_to_AHB_Bridge DUT (HCLK,RESET_n,HSEL,HADDR,HWRITE,HREADY,HWDATA,HREADYOUT,HRDATA,PSEL,PADDR,PENABLE,PWRITE,PWDATA,PRDATA);

    // Slave instantiation
    Slaves Slaves_inst (PADDR,PWDATA,PSEL,PWRITE,PENABLE,PRDATA);

    // clk generator
    initial begin
        HCLK = 0;
        forever #1 HCLK = ~HCLK;
    end

    // test cases
    initial begin
        // assert reset signal (active low)
        RESET_n = 0;
        #10;
        // de-assert reset signal
        RESET_n = 1;
        #100;
        // Cycle 1: Operation 1
        @(negedge HCLK)
        HSEL = 1; // Master chooses bridge slave for operation 1
        HWRITE = 1; // Write operation
        HADDR[4:0] = $random; //Address 1
        HADDR[6:5] = $random; // Targetted slave
        HREADY = 1;
        // Cycle2: Operation 2
        @(negedge HCLK)
        HWDATA = $random; // Data for operation 1
        HSEL = 1; // Master chooses bridge slave for operation 2
        HWRITE = 1; // Write operation
        HADDR[4:0] = $random; //Address 2
        HADDR[6:5] = $random; // Targetted slave
        HREADY = 1;
        // Cycle 3: Operation 3
        @(negedge HCLK)
        HWDATA = $random; // Data for operation 2
        HSEL = 1; // Master chooses bridge slave for operation 3
        HWRITE = 1; // Write operation
        HADDR[4:0] = $random; //Address 3
        HADDR[6:5] = $random; // Targetted slave
        HREADY = 0;
        // Cycle 4:
        @(negedge HCLK)
        HSEL = 0; // Master raises HSEL for only one cycle per operation
        HREADY = 1;
        // Cycle 5: Operation 4
        @(negedge HCLK)
        HWDATA = $random; // Data for operation 3
        HSEL = 1; // Master chooses bridge slave for operation 4
        HWRITE = 1; // Write operation
        HADDR[4:0] = $random; //Address 4
        HADDR[6:5] = $random; // Targetted slave
        HREADY = 0;
        // Cycle 6:
        @(negedge HCLK)
        HSEL = 0; // Master raises HSEL for only one cycle per operation
        HREADY = 1;
        // Cycle 7:
        @(negedge HCLK)
        HWDATA = $random; // Data for operation 4
        HREADY = 0;
        // Cycle 8:
        @(negedge HCLK)
        HREADY = 1;
        // Cycle 9:
        @(negedge HCLK)
        HREADY = 0;
        // Cycle 10:
        @(negedge HCLK)
        HREADY = 1;
        #8;
        $stop;
    end

    // monitor block
endmodule