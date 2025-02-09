// DO NOT MODIFY THE MODULE NAMES, SIGNAL NAMES, SIGNAL PROPERTIES

module bonuslab (
  input            clk  ,
  input            rst  ,
  input            start,
  input      [1:0] X    ,
  input      [1:0] Y    ,
  input            pAb  ,
  input            pBb  ,
  output reg [7:0] disp0,
  output reg [7:0] disp1,
  output reg [7:0] disp2,
  output reg [7:0] disp3,
  output reg [7:0] led
);

/* Your design goes here. */

  // State Encoding
  parameter IDLE       = 5'b00000,
            SHOW_A     = 5'b00001,
            A_IN       = 5'b00010,
            ERROR_A    = 5'b00011,
            SHOW_B     = 5'b00100,
            B_IN       = 5'b00101,
            ERROR_B    = 5'b00110,
            SHOW_SCORE = 5'b00111,
            A_SHOOT    = 5'b01000,
            A_SINK     = 5'b01001,
            B_SHOOT    = 5'b01010,
            B_SINK     = 5'b01011,
            A_WIN      = 5'b01100,
            B_WIN      = 5'b01101,
            A_WIN1     = 5'b01110,
            B_WIN1     = 5'b01111,
            SHOW_A_end = 5'b10000,
            SHOW_B_end = 5'b10001;

  reg [4:0] current_state; // FSM state registers
  reg [15:0] mapA, mapB;               // Player maps (4x4 grid)
  reg [2:0] scoreA, scoreB;            // Player scores
  reg [2:0] total_scoreA, total_scoreB; 
  reg [1:0] input_count;               // Ship placement counter
  reg [31:0] timer;
  reg Z;
  reg first ; // 0 if A's input is first, 1 if B's input is first           
  wire [3:0] index;




  assign index = X*4+Y;

  // Sequential Logic: State Transitions
always @(posedge clk) begin
  if (rst) begin
    current_state <= IDLE;
    timer <= 0;
    mapA <= 16'b0;
    mapB <= 16'b0;
    scoreA <= 3'b000;
    scoreB <= 3'b000;
    input_count <= 3'b0;
    Z<=0;
    total_scoreA <= 3'b0;
    total_scoreB <= 3'b0;
    first<= 1'b0;

  end else begin
    case (current_state)
      IDLE: begin
        if (start) begin
          timer<= 0;
          if (first == 1'b0) begin
              current_state <= SHOW_A;
          end
          else begin 
              current_state <= SHOW_B;
          end
          
        end
      end

      SHOW_A: begin
        if (timer < 32'd50) begin
          timer <= timer + 1;
        end else begin
          timer <= 0;
          current_state <= A_IN;
        end
      end

      A_IN: begin
        if (pAb) begin
          if (mapA[index]) begin
            current_state <= ERROR_A; // Position occupied
          end else if (input_count > 2) begin
            mapA[index] <= 1; // Mark position
            input_count <= 0;
            if (first == 1'b0) 
              current_state <= SHOW_B;
            else 
              current_state <= SHOW_SCORE; 
          end else begin
            mapA[index] <= 1; // Mark position
            input_count <= input_count + 1;
          end
        end
        else begin
          current_state <= A_IN;
        end

      end
      ERROR_A: begin
        if (timer < 32'd50) begin
          timer <= timer + 1;
        end else begin
          timer <= 0;
          current_state <= A_IN;
        end
      end

      SHOW_B: begin
        if (timer < 32'd50) begin
          timer <= timer + 1;
        end else begin
          timer <= 0;
          current_state <= B_IN;
        end
      end

      B_IN: begin
        if (pBb) begin
          if (mapB[index]) begin
            current_state <= ERROR_B; // Position occupied
          end else if (input_count > 2) begin
            mapB[index] <= 1; // Mark position
            input_count <= 0;
            if (first == 1'b1) 
              current_state <= A_IN;
            else 
              current_state <= SHOW_SCORE; 
          end else begin
            mapB[index] <= 1; // Mark position
            input_count <= input_count + 1;
          end
        end
      end

      ERROR_B: begin
        if (timer < 32'd50) begin
          timer <= timer + 1;
        end else begin
          timer <= 0;
          current_state <= B_IN;
        end
      end

      SHOW_SCORE: begin
        if (timer < 32'd50) begin
          timer <= timer + 1;
        end else begin
          timer <= 0;
          if (first == 1'b0)
              current_state <= A_SHOOT;
          else 
              current_state <= B_SHOOT;
        end
      end

      A_SHOOT: begin
        if (pAb) begin
          if (mapB[index] == 1) begin
            mapB[index] <= 0; // Sink ship
            scoreA <= scoreA + 1;
            current_state <= A_SINK;
            Z<=1;
          end else begin
            current_state <= A_SINK;
            Z<=0;
          end
        end
      end

      B_SHOOT: begin
        if (pBb) begin
          if (mapA[index] == 1) begin
            mapA[index] <= 0; // Sink ship
            scoreB <= scoreB + 1;
            current_state <= B_SINK;
            Z<=1;
          end else begin
            current_state <= B_SINK;
            Z<=0;
          end
        end
      end

      A_SINK: begin
        if (timer < 32'd50) begin
          timer <= timer + 1;
        end else begin 
          timer <= 0;
          if (scoreA ==2 ) begin 
            current_state <= SHOW_A_end;
            total_scoreA <= total_scoreA +1;
            input_count<=0;
            mapA <= 15'd0;
            mapB<= 15'd0;               
            scoreA<= 3'd0;
            scoreB <= 3'd0;
          end else begin
            current_state <= B_SHOOT;
          end
        end
      end

      B_SINK: begin
        if (timer < 32'd50) begin
          timer <= timer + 1;
        end else begin
          timer <= 0;
          if (scoreB == 2) begin
              current_state <= SHOW_B_end;
              total_scoreB <= total_scoreB +1;
              input_count<=0;
              mapA <= 15'd0;
              mapB<= 15'd0;               
              scoreA<= 3'd0;
              scoreB <= 3'd0;
          end else begin
            current_state <= A_SHOOT;
          end
        end
      end

      SHOW_A_end:begin
          if (timer < 32'd50) begin
              timer <= timer + 1;
          end else begin
              timer<=0;
              if (total_scoreA + total_scoreB ==3)begin
                  current_state <=A_WIN;
              end
              else begin
                  current_state <= SHOW_A;
                  first<=1'b0;
              end
          end
      end

      SHOW_B_end:begin
          if (timer < 32'd50) begin
              timer <= timer + 1;
          end else begin
              timer<=0;
              if (total_scoreA + total_scoreB ==3)begin
                  current_state <=B_WIN;
              end
              else begin
                  current_state <= SHOW_B;
                  first<=1'b1;
              end
          end
      end



      A_WIN: begin 
        if (timer < 32'd2) begin
          timer <= timer + 1;
      end else begin
        timer <= 0;
        current_state<= A_WIN1;
      end
    end
      A_WIN1: begin 
        if (timer < 32'd2) begin
          timer <= timer + 1;
      end else begin
        timer <= 0;
        current_state<= A_WIN;
      end
    end

      B_WIN: begin 
        if (timer < 32'd2) begin
          timer <= timer + 1;
      end else begin
        timer <= 0;
        current_state<= B_WIN1;
      end
    end

      B_WIN1: begin 
        if (timer < 32'd2) begin
          timer <= timer + 1;
      end else begin
        timer <= 0;
        current_state<= B_WIN;
      end
    end
    endcase
  end
end
  // Output Logic
  always @(*) begin
    // Default Outputs
    disp0 = 8'b00000000;
    disp1 = 8'b00000000;
    disp2 = 8'b00000000;
    disp3 = 8'b00000000;
    led = 8'b00000000;

    case (current_state)
      IDLE: begin
        disp0 = 8'b01111001; // "IDLE"
        disp1 = 8'b00111000;
        disp2 = 8'b01011110;
        disp3 = 8'b00000110;
        led = 8'b10011001;
      
      end

      SHOW_A: begin
        disp3 = 8'b01110111; // "A"
      end

      A_IN: begin
        // Display real-time coordinates
        case (Y)
          2'b00: disp0 = 8'b00111111; // "0"
          2'b01: disp0 = 8'b00000110; // "1"
          2'b10: disp0 = 8'b01011011; // "2"
          2'b11: disp0 = 8'b01001111; // "3"
        endcase
        case (X)
          2'b00: disp1 = 8'b00111111; // "0"
          2'b01: disp1 = 8'b00000110; // "1"
          2'b10: disp1 = 8'b01011011; // "2"
          2'b11: disp1 = 8'b01001111; // "3"
        endcase
        disp3 = 8'b00000000; 
        disp2 = 8'b00000000;
        led[7]= 1'b1;  
        led[5:4] = input_count[1:0]; // Player A input count
      end

      ERROR_A: begin
        disp0 = 8'b00111111; // "O"
        disp1 = 8'b01010000; // "R"
        disp2 = 8'b01010000; // "R"
        disp3 = 8'b01111001; // "E"
        led   = 8'b10011001;   // Indicate error state
      end

      SHOW_B: begin
        disp3 = 8'b01111100; // "b"
      end

      B_IN: begin
        // Display real-time coordinates
        case (Y)
          2'b00: disp0 = 8'b00111111; // "0"         
          2'b01: disp0 = 8'b00000110; // "1"
          2'b10: disp0 = 8'b01011011; // "2"
          2'b11: disp0 = 8'b01001111; // "3"
        endcase
        case (X)
          2'b00: disp1 = 8'b00111111; // "0"
          2'b01: disp1 = 8'b00000110; // "1"
          2'b10: disp1 = 8'b01011011; // "2"
          2'b11: disp1 = 8'b01001111; // "3"
        endcase
        disp3 = 8'b00000000; 
        disp2 = 8'b00000000; 
        led[3:2] = input_count[1:0]; // Player B input count
        led[0]= 1'b1;  
      end

      ERROR_B: begin
        disp0 = 8'b00111111; // "O"
        disp1 = 8'b01010000; // "R"
        disp2 = 8'b01010000; // "R"
        disp3 = 8'b01111001; // "E"
        led   = 8'b10011001;   // Indicate error state
      end

      SHOW_SCORE: begin
        // Display "0-0" initially for scores
        disp2 = 8'b00111111; // "0"
        disp1 = 8'b01000000; // "-" Separator
        disp0 = 8'b00111111; // "0"


        // Light up LEDs 7, 4, 3, and 0 for one second
        led = 8'b10011001;
      end

      A_SHOOT: begin
        // Real-time display of X, Y coordinates
        case (Y)
          2'b00: disp0 = 8'b00111111; // "0"
          2'b01: disp0 = 8'b00000110; // "1"
          2'b10: disp0 = 8'b01011011; // "2"
          2'b11: disp0 = 8'b01001111; // "3"
        endcase
        case (X)
          2'b00: disp1 = 8'b00111111; // "0"
          2'b01: disp1 = 8'b00000110; // "1"
          2'b10: disp1 = 8'b01011011; // "2"
          2'b11: disp1 = 8'b01001111; // "3"
        endcase

        // Indicate turn for Player A on LED[7]
        led[7] = 1'b1;

        // Display scores on LEDs (LED 5-4 for Player A, LED 3-2 for Player B)
        led[5:4] = scoreA;
        led[3:2] = scoreB;
      end

      A_SINK: begin
        // Update score
        case (scoreA)
          
          3'b000: disp2 = 8'b00111111; // "0"
          3'b001: disp2 = 8'b00000110; // "1"
          3'b010: disp2 = 8'b01011011; // "2"
          3'b011: disp2 = 8'b01001111; // "3"
          3'b100: disp2 = 8'b01100110; // "4"
        endcase

        disp1 = 8'b01000000; // "-" Separator

        case (scoreB)
         
          3'b000: disp0 = 8'b00111111; // "0"
          3'b001: disp0 = 8'b00000110; // "1"
          3'b010: disp0 = 8'b01011011; // "2"
          3'b011: disp0 = 8'b01001111; // "3"
          3'b100: disp0 = 8'b01100110; // "4"
         endcase

        if (Z) begin
          led = 8'b11111111; 
        end else begin
          led = 8'b00000000; 
        end
      end

      B_SHOOT: begin
        // Real-time display of X, Y coordinates
        case (Y)
          2'b00: disp0 = 8'b00111111; // "0"
          2'b01: disp0 = 8'b00000110; // "1"
          2'b10: disp0 = 8'b01011011; // "2"
          2'b11: disp0 = 8'b01001111; // "3"
        endcase
        case (X)
          2'b00: disp1 = 8'b00111111; // "0"
          2'b01: disp1 = 8'b00000110; // "1"
          2'b10: disp1 = 8'b01011011; // "2"
          2'b11: disp1 = 8'b01001111; // "3"
        endcase

      
        // Indicate turn for Player B on LED[6]
        led[0] = 1'b1;

        // Display scores on LEDs (LED 5-4 for Player A, LED 3-2 for Player B)
        led[5:4] = scoreA;
        led[3:2] = scoreB;
      end

      B_SINK: begin
        // Update score
        case (scoreA)
            
          3'b000: disp2 = 8'b00111111; // "0"
          3'b001: disp2 = 8'b00000110; // "1"
          3'b010: disp2 = 8'b01011011; // "2"
          3'b011: disp2 = 8'b01001111; // "3"
          3'b100: disp2 = 8'b01100110; // "4"
        endcase

        disp1 = 8'b01000000; // "-" Separator

        case (scoreB)
         
          3'b000: disp0 = 8'b00111111; // "0"
          3'b001: disp0 = 8'b00000110; // "1"
          3'b010: disp0 = 8'b01011011; // "2"
          3'b011: disp0 = 8'b01001111; // "3"
          3'b100: disp0 = 8'b01100110; // "4"
        endcase

        if (Z) begin
          led = 8'b11111111; 
        end else begin
          led = 8'b00000000; 
        end
      end

      SHOW_A_end: begin
          case (total_scoreA)
          
              3'b000: disp2 = 8'b00111111; // "0"
              3'b001: disp2 = 8'b00000110; // "1"
              3'b010: disp2 = 8'b01011011; // "2"
              3'b011: disp2 = 8'b01001111; // "3"
              3'b100: disp2 = 8'b01100110; // "4"
          endcase

          disp1 = 8'b01000000; // "-" Separator

          case (total_scoreB)
              
              3'b000: disp0 = 8'b00111111; // "0"
              3'b001: disp0 = 8'b00000110; // "1"
              3'b010: disp0 = 8'b01011011; // "2"
              3'b011: disp0 = 8'b01001111; // "3"
              3'b100: disp0 = 8'b01100110; // "4"
          endcase
          led = 8'b11111111;
      end

      SHOW_B_end: begin
          case (total_scoreA)
          
              3'b000: disp2 = 8'b00111111; // "0"
              3'b001: disp2 = 8'b00000110; // "1"
              3'b010: disp2 = 8'b01011011; // "2"
              3'b011: disp2 = 8'b01001111; // "3"
              3'b100: disp2 = 8'b01100110; // "4"
          endcase

          disp1 = 8'b01000000; // "-" Separator

          case (total_scoreB)
              
              3'b000: disp0 = 8'b00111111; // "0"
              3'b001: disp0 = 8'b00000110; // "1"
              3'b010: disp0 = 8'b01011011; // "2"
              3'b011: disp0 = 8'b01001111; // "3"
              3'b100: disp0 = 8'b01100110; // "4"
          endcase
          led = 8'b11111111;
      end

      A_WIN: begin
        disp3 = 8'b01110111; // "A"
        case (total_scoreA)
         
            3'b000: disp2 = 8'b00111111; // "0"
            3'b001: disp2 = 8'b00000110; // "1"
            3'b010: disp2 = 8'b01011011; // "2"
            3'b011: disp2 = 8'b01001111; // "3"
            3'b100: disp2 = 8'b01100110; // "4"
        endcase

        disp1 = 8'b01000000; // "-" Separator

        case (total_scoreB)
          
            3'b000: disp0 = 8'b00111111; // "0"
            3'b001: disp0 = 8'b00000110; // "1"
            3'b010: disp0 = 8'b01011011; // "2"
            3'b011: disp0 = 8'b01001111; // "3"
            3'b100: disp0 = 8'b01100110; // "4"
        endcase
        led= 8'b10101010;
      end

      A_WIN1: begin
        disp3 = 8'b01110111; // "A"
        case (total_scoreA)
         
            3'b000: disp2 = 8'b00111111; // "0"
            3'b001: disp2 = 8'b00000110; // "1"
            3'b010: disp2 = 8'b01011011; // "2"
            3'b011: disp2 = 8'b01001111; // "3"
            3'b100: disp2 = 8'b01100110; // "4"
          
        endcase

        disp1 = 8'b01000000; // "-" Separator

        case (total_scoreB)
          
          3'b000: disp0 = 8'b00111111; // "0"
          3'b001: disp0 = 8'b00000110; // "1"
          3'b010: disp0 = 8'b01011011; // "2"
          3'b011: disp0 = 8'b01001111; // "3"
          3'b100: disp0 = 8'b01100110; // "4"
        endcase
        led= 8'b01010101;
      
      end

      B_WIN: begin
        disp3 = 8'b01111100; // "b"
        case (total_scoreA)
         
          3'b000: disp2 = 8'b00111111; // "0"
          3'b001: disp2 = 8'b00000110; // "1"
          3'b010: disp2 = 8'b01011011; // "2"
          3'b011: disp2 = 8'b01001111; // "3"
          3'b100: disp2 = 8'b01100110; // "4"
        endcase

        disp1 = 8'b01000000; // "-" Separator

        case (total_scoreB)
          
          3'b000: disp0 = 8'b00111111; // "0"
          3'b001: disp0 = 8'b00000110; // "1"
          3'b010: disp0 = 8'b01011011; // "2"
          3'b011: disp0 = 8'b01001111; // "3"
          3'b100: disp0 = 8'b01100110; // "4"
        endcase
        led= 8'b10101010;
      end

      B_WIN1: begin
        disp3 = 8'b01111100; // "b"
        case (total_scoreA)
         
          3'b000: disp2 = 8'b00111111; // "0"
          3'b001: disp2 = 8'b00000110; // "1"
          3'b010: disp2 = 8'b01011011; // "2"
          3'b011: disp2 = 8'b01001111; // "3"
          3'b100: disp2 = 8'b01100110; // "4"
        endcase

        disp1 = 8'b01000000; // "-" Separator

        case (total_scoreB)
          
          3'b000: disp0 = 8'b00111111; // "0"
          3'b001: disp0 = 8'b00000110; // "1"
          3'b010: disp0 = 8'b01011011; // "2"
          3'b011: disp0 = 8'b01001111; // "3"
          3'b100: disp0 = 8'b01100110; // "4"
        endcase
          led= 8'b01010101;
      end

      default: begin
        disp0 = 8'b00000000;
        disp1 = 8'b00000000;
        disp2 = 8'b00000000;
        disp3 = 8'b00000000;
        led = 8'b00000000;
      end
    endcase
  end
endmodule

