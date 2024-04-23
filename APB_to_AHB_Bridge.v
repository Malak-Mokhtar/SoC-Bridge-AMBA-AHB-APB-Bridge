module APB_to_AHB_Bridge(HCLK,RESET_n,HSEL,HADDR,HWRITE,HREADY,HWDATA,HREADYOUT,HRDATA,PSEL,PADDR,PENABLE,PWRITE,PWDATA,PRDATA);

    // -------------------------------- Inputs/Outputs/reg/localparam Declarations -------------------------------- //

    // States:
    localparam IDLE = 3'b000;
    localparam WAIT = 3'b001;
    localparam WRITE_SETUP = 3'b010;
    localparam WRITE_ENABLE =  3'b011;
    localparam READ_SETUP = 3'b100;
    localparam READ_ENABLE = 3'b101;

    // Inputs:
    input HCLK,RESET_n,HSEL,HWRITE,HREADY;
    input [6:0] HADDR; // (2 BITS PSEL) + (5 BITS PADDR)
    input [31:0] HWDATA, PRDATA;

    // Outputs:
    output reg HREADYOUT,PENABLE,PWRITE;
    output reg [3:0] PSEL; // OUT OF DECODER
    output reg [4:0] PADDR;
    output reg [31:0] HRDATA,PWDATA;

    // Registers:
    reg [2:0] cs,ns; // current state and next state registers
    reg [6:0] reg1; // Holds current address
    reg [6:0] reg2; // Holds new address
    reg [31:0] reg3; // Holds data
    reg reg4; // Holds new HWRITE
    reg reg5; // Holds new HSEL
    reg reg6; // Holds last HSEL
    reg reg7; // Holds last HWRITE

    reg LAST_OP;


    // -------------------------------- State storage element -------------------------------- //
    always @(posedge HCLK or negedge RESET_n) begin
        if(!RESET_n)
            cs <= IDLE;
        else begin
            cs <= ns;
        end
    end

    // -------------------------------- Next state logic -------------------------------- //
    always @(*) begin
        case (cs)
            IDLE: ns = !HSEL ? IDLE : HWRITE ? WAIT : READ_SETUP;
            WAIT: ns = WRITE_SETUP;
            WRITE_SETUP: ns = WRITE_ENABLE;
            WRITE_ENABLE: begin // -- CHECK
              ns = (!reg5 && !reg6 && HSEL && HWRITE) ? WAIT : // W NOP NOP W
                   ((reg5 && !reg4) || (!reg5 && (!reg6 && HSEL && !HWRITE))) ? READ_SETUP : // (new Hsel = 1 and new HWrite = 0 -> W R) OR (W NOP NOP R)
                   (!reg5 && reg6 && !reg7) ? READ_ENABLE : // W NOP R
                   ((reg5 && reg4) || (!reg5 && reg6 && reg7)) ? WRITE_SETUP : // (W W) OR (W NOP W)
                   IDLE; // (W NOP NOP NOP W) OR (W NOP NOP NOP R) OR (W NOP NOP NOP NOP...)
            end
            READ_SETUP: ns = READ_ENABLE;
            READ_ENABLE: ns = (reg5 && !reg4) ? READ_SETUP : // new HSEL = 1 and new HWRITE = 0 -> ANOTHER READ OPERATION (RR)
                              (reg5 && reg4) || (reg6 && reg7) ?  WAIT : // new HSEL = 1 and new HWRITE = 1 -> NEW WRITE OPERATION (RW) -- CHECK 2nd condition
                              (reg6 && !reg7) ? READ_SETUP : // CHECK new condition
                            IDLE;
            default: ns = IDLE;
        endcase
    end

    // -------------------------------- Output logic -------------------------------- //
    always @(*) begin
        case (cs)
            IDLE: begin
                PENABLE = 0;
                HREADYOUT = 1;
                if (LAST_OP) begin
                    PENABLE = 1;
                end
                if (!HREADY) begin // active low CHANGED HERE, added condition
                    PADDR = reg1[4:0];
                    PWDATA = reg3;
                end
            end
            READ_SETUP: begin
                if (!HREADY) // active low
                    PADDR = reg1[4:0];
                PWRITE = 0;
                PENABLE = 0;
                HREADYOUT = HREADY;
            end
            READ_ENABLE: begin
                PENABLE = 1;
                PWRITE = 0;
                HREADYOUT = 1;
                HRDATA = PRDATA;
            end
            WAIT: begin
                PENABLE = 0;
                HREADYOUT = 1;
                PWRITE = 0; // to avoid latching
            end
            WRITE_SETUP: begin
                if (!HREADY) begin // active low
                    PADDR = reg1[4:0];
                    PWDATA = reg3;
                end
                PENABLE = 0;
                PWRITE = 1;
                HREADYOUT = HREADY;
            end
            WRITE_ENABLE: begin
                PENABLE = 1;
                PWRITE = 1;
                HREADYOUT = 1;
            end
            default: begin // to avoid latching
                PENABLE = 0;
                PWRITE = 0;
                HREADYOUT = HREADY;
            end
        endcase
    end

    // -------------------------------- Temporary Registers -------------------------------- //
    // Block 1 temporary storage element
    always @(posedge HCLK or negedge RESET_n) begin
        if (!RESET_n) begin
            reg1 <= 0;
        end
        else if ((cs == IDLE ) && HSEL) begin
            reg1 <= HADDR;
        end
        // Moving between registers
        else if ((cs == WRITE_ENABLE) || (cs == READ_ENABLE)) begin
                if (reg5) // if new HSEL = 1
                    reg1 <= reg2; // Move address from reg2 to current address
                else if(reg6)
                    reg1 <= reg2;
            end
        else if ((cs == WAIT) || (cs == WRITE_SETUP)) begin
                if(reg6)
                    reg1 <= reg2;
            end
    end

    // Block 2 temporary storage element
    always @(posedge HCLK or negedge RESET_n) begin
        if (!RESET_n) begin
            reg2 <= 0;
            reg3 <= 0;
            reg4 <= 0;
            reg5 <=0;
        end
        else begin
            // Register holding new address -- CHECK
            if ((HSEL && ((cs == WAIT) || (cs == READ_SETUP))) || (cs == WRITE_ENABLE && ((ns == WRITE_SETUP) || (ns == WAIT) || (ns == READ_SETUP) || (ns == READ_ENABLE)))) begin
                reg2 <= HADDR;
            end
            // Register holding data CHANGED HERE
            if ((cs == WAIT) || (cs == WRITE_ENABLE && ns == WRITE_SETUP) || (!reg5 && (cs == WRITE_SETUP) && (ns == WRITE_ENABLE))) begin
                reg3 <= HWDATA;
            end
            // Register holding new HWRITE
            if ((HSEL && ((cs == WAIT) || (cs == READ_SETUP))) || (cs == WRITE_ENABLE && ((ns == WRITE_SETUP) || (ns == WAIT) || (ns == READ_SETUP) || (ns == READ_ENABLE)))) begin
                reg4 <= HWRITE;
            end
            // Register holding new HSEL
            if ((cs == WAIT) || (cs == READ_SETUP) ) begin
                reg5 <= HSEL;
            end
            else if((cs == READ_ENABLE) || (cs == WRITE_ENABLE)) // CHANGED HERE Added condition
                reg5 <= 0;
        end
    end

    // Block 3 temporary storage element
    always @(posedge HCLK or negedge RESET_n) begin
        if (!RESET_n) begin
            reg6 <= 0;
            reg7 <= 0;
        end
        else begin
            // Register holding last HSEL and Register holding last HWRITE
            if ((cs == WRITE_SETUP) || (!reg6 && cs == WRITE_ENABLE)) begin
                reg6 <= HSEL;
                reg7 <= HWRITE;
            end
        end
    end

    // to handle last operation before going to IDLE
    always @(posedge HCLK or negedge RESET_n) begin
        if (!RESET_n)
            LAST_OP = 0;
        else if((cs == IDLE) && !HREADY)
            LAST_OP <= 1;
        else
            LAST_OP <= 0;
    end

    // -------------------------------- Decoder for PSEL output (depends on 2 MSB from HADDR by master) -------------------------------- //
    always @(*) begin
        case (reg1[6:5]) // current address
            2'b00: PSEL = 4'b0001;
            2'b01: PSEL = 4'b0010;
            2'b10: PSEL = 4'b0100;
            2'b11: PSEL = 4'b1000;
        endcase
    end



endmodule