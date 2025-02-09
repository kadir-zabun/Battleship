// DO NOT CHANGE THE NAME OR THE SIGNALS OF THIS MODULE

module top (
  input        clk    ,
  input  [3:0] sw     ,
  input  [3:0] btn    ,
  output [7:0] led    ,
  output [7:0] seven  ,
  output [3:0] segment
);

  wire new_clk;  // for clk_divider         
  wire new_rst, new_start; //for debouncer 
  wire new_btnA, new_btnB; //for debouncer

  // new variables for ssd module
  wire [7:0] disp0, disp1, disp2, disp3;

  // changed clk signal
  clk_divider clk_div_inst (
    .clk_in(clk),
    .divided_clk(new_clk)
  );

  // debouncers for the buttons
  debouncer db_rst (
    .clk(new_clk),
    .rst(1'b0),             
    .noisy_in(btn[2]),      
    .clean_out(new_rst)
  );

  debouncer db_start (
    .clk(new_clk),
    .rst(1'b0),
    .noisy_in(btn[1]),     
    .clean_out(new_start)
  );

  debouncer db_btn_a (
    .clk(new_clk),
    .rst(1'b0),
    .noisy_in(btn[3]),      
    .clean_out(new_btnA)
  );

  debouncer db_btn_b (
    .clk(new_clk),
    .rst(1'b0),
    .noisy_in(btn[0]),      
    .clean_out(new_btnB)
  );

  // main battleship game logic
  bonuslab game (
    .clk(new_clk),      
    .rst(new_rst),        
    .start(new_start),    
    .X(sw[3:2]), 
    .Y(sw[1:0]),        
    .pAb(new_btnA),   
    .pBb(new_btnB),    
    .disp0(disp0),        
    .disp1(disp1),          
    .disp2(disp2),       
    .disp3(disp3),        
    .led(led)               
  );

  // Instantiate the seven-segment display driver
  ssd ssd_driver (
    .clk(clk),              
    .disp0(disp0),         
    .disp1(disp1),         
    .disp2(disp2),          
    .disp3(disp3),          
    .seven(seven),          
    .segment(segment)       
  );

endmodule