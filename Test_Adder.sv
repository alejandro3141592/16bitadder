module test_bfloat16_adder;
  logic [15:0] sum;
  logic ready;
  logic [15:0] a, b;
  logic clock;
  logic n_reset;
  logic sign_num1, sign_num2;

  logic [7:0] exponent_num1, exponent_num2, mantissa_num1, mantissa_num2, diference, exponent_sum;
  logic [8:0] mantissa_sum;


  bfloat16_adder a1 (.*);

    initial
    begin
      n_reset = '1;
      clock = '0;
      #5ns n_reset = '1;
      #5ns n_reset = '0;
      #5ns n_reset = '1;
      forever #5ns clock = ~clock;
    end


  initial begin

    // @(posedge ready);
    // @(posedge clock);
    // a = 'b0000000010000001;
    // b = 'b0000000010000001;

    // #80ns

    // a = 'b0000000010000001;
    // b = 'b0000000010000010;


    // #80ns

    // a = 'b0000000010000011;
    // b = 'b0000000010000001;
    // #80ns

    // a = 'b0000000110000001;
    // b = 'b0000000010000001;

    // #80ns

    // a = 'b0000000010000001;
    // b = 'b0000000110000001;

    // #80ns

    a = 'b0000000000000000;
    b = 'b0000000000000000;

     #80ns

    a = 'b0000000000000000;
    b = 'b0000000000000001;

     #80ns

    a = 'b0000000000000001;
    b = 'b0000000000000001;


     #80ns

    a = 'b000000000000000;
    b = 'b0000000000000001;


    $display("Test 12 %d\n", sum);
    $stop;
  end

  initial begin
    
        $monitor("Time: %0dps, a: %b, b: %b, sum: %b, ready: %b",
                 $time, a, b, sum, ready);
    end

endmodule