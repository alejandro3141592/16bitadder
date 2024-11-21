`timescale 1ns/1ps

module test_bfloat16_adder;

  logic [15:0] sum;
  logic ready;
  logic [15:0] a, b;
  logic clock;
  logic n_reset;
  logic sign_num1, sign_num2, sign_sum;

  logic [7:0] exponent_num1, exponent_num2,  diference, exponent_sum;
  logic [8:0] mantissa_sum;
  logic [6:0] mantissa_num1, mantissa_num2;

  // Parameters
  parameter DATA_WIDTH = 16;


  // File handling variables
  integer file, status;
  reg [255:0] line; // Line buffer
  reg [DATA_WIDTH-1:0] expected;

  // Instantiate the adder module
  bfloat16_adder a1 (.*);

  // Clock generation
  initial
    begin
      n_reset = '1;
      clock = '0;
      #5ns n_reset = '1;
      #5ns n_reset = '0;
      #5ns n_reset = '1;
      forever #5ns clock = ~clock;
    end

  // Task to process a test case
  task process_test(input [DATA_WIDTH-1:0] in1, input [DATA_WIDTH-1:0] in2, input [DATA_WIDTH-1:0] expected_result);
    begin
      a = in1;
      b = in2;
      @(posedge ready)// Wait for result
      if (sum !== expected_result) begin
        $display("ERROR: a = %h, b = %h, Expected = %h, Got = %h", in1, in2, expected_result, sum);
      end else begin
        $display("PASS: a = %h, b = %h, Result = %h", in1, in2, sum);
      end
    end
  endtask

  // Initialization and test sequences
  initial begin
    // Initialize inputs
    clock = 0;
    n_reset = 1;
    a = 0;
    b = 0;

    // Apply reset
    #10 n_reset = 0;

    // Open the file
    file = $fopen("C:/Users/mtzal/OneDrive/Documentos/Adder16/test_cases.txt", "r");
    if (file == 0) begin
      $display("ERROR: Unable to open file!");
      $finish;
    end

    // Read the file line by line
    while (!$feof(file)) begin
      status = $fgets(line, file); // Read a line
      if (status != 0) begin
        // Parse the line: read input_a, input_b, and expected_sum
        status = $sscanf(line, "%h %h %h", a, b, expected);
        if (status == 3) begin
          process_test(a, b, expected);
        end else begin
          $display("ERROR: Malformed line in file: %s", line);
        end
      end
    end

    // Close the file
    $fclose(file);

    // Finish simulation
    $stop;
  end

endmodule
