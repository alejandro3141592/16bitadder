module bfloat16_adder (
    output logic [15:0] sum,
    output logic ready,
    input logic [15:0] a,
    b,
    input logic clock,
    n_reset,
    output logic sign_num1,
    sign_num2,
    output logic [7:0] exponent_num1,
    exponent_num2,
    mantissa_num1,
    mantissa_num2,
    diference,
    exponent_sum,
    output logic [8:0] mantissa_sum
);

  logic [15:0] num1, num2, result;

  logic [9:0] mantissa_num1_aux, mantissa_num2_aux;

  enum {
    adder_ready,
    reading_first_input,
    reading_second_input,
    checking_zero_exp_num1,
    num1_zero,
    num1_almost_zero,
    checking_zero_exp_num2,
    num2_zero,
    num2_almost_zero,
    checking_255_exp_num1, 
    num1_inf,
    num1_Nan, 
    checking_255_exp_num2, 
    equalize_exponents, 
    add_mantisas, 
    normalize_number, 
    N,
    O, 
    P,
    Q, 
    AA
  } present_state, next_state;


  always_ff @(posedge clock, negedge n_reset) begin : SEQ
    if (~n_reset) present_state <= adder_ready;
    else present_state <= next_state;
  end


  always_comb begin : COM


    case (present_state)

      adder_ready: begin
        ready = 1'b1;
        sum = result;
        next_state = reading_first_input;
      end

      reading_first_input: begin
        //Read Input A
        ready = 1'b0;
        num1 = a;
        sign_num1 = num1[15];
        exponent_num1 = num1[14:7];
        mantissa_num1 = num1[6:0];

        next_state = reading_second_input;
      end

      reading_second_input: begin
        //Read Input B
        num2 = b;
        sign_num2 = num2[15];
        exponent_num2 = num2[14:7];
        mantissa_num2 = num2[6:0];
        next_state = checking_zero_exp_num1;
      end

      checking_zero_exp_num1: begin
        if (exponent_num1 == 8'd0) begin
          if (mantissa_num1 == 8'd0) begin
            next_state = num1_zero;
          end else begin
            next_state = num1_almost_zero;
          end
        end else begin
          mantissa_num1_aux = {1'b1, mantissa_num1};
          next_state = checking_zero_exp_num2;
        end
      end

      num1_zero: begin
        result = (sign_num1) ? {~sign_num2, exponent_num2, mantissa_num2} : num2;
        next_state = adder_ready;
      end

      num1_almost_zero: begin
        mantissa_num1_aux = {1'b0, mantissa_num1};
        next_state = checking_zero_exp_num2;
      end

      checking_zero_exp_num2: begin
        if (exponent_num2 == 8'd0) begin
          if (mantissa_num2 == 8'd0) begin
            next_state = num2_zero;
          end else begin
            next_state = num2_almost_zero;
          end
        end else begin
          mantissa_num1_aux = {1'b1, mantissa_num1};
          next_state = checking_255_exp_num1;
        end 
      end

      num2_zero: begin
        result = (sign_num2) ? {~sign_num1, exponent_num1, mantissa_num1} : num1;
        next_state = adder_ready;
      end 

      num2_almost_zero: begin
        mantissa_num2_aux = {1'b0, mantissa_num2};
        next_state = checking_255_exp_num1;
      end 

      checking_255_exp_num1: begin
        if (exponent_num1 == 8'd255) begin
          if (mantissa_num1 == 8'd0) begin
            next_state = num1_inf;
          end else begin
            next_state = num1_Nan;
          end
        end else begin
          next_state = checking_255_exp_num2;
        end 

      end 

      num1_inf: begin
        if (exponent_num2 == 8'd255) begin
          if (mantissa_num2 == 8'd0) begin
            result = (sign_num1 == sign_num2) ? num1 : {num1, 8'd255, 7'd1};
          end else begin
            result = num2;
          end
        end else begin
          result = num1;
        end 
        next_state = adder_ready;
      end 

      num1_Nan : begin
        result = num1;
        next_state = adder_ready;
      end

      checking_255_exp_num2: begin
        if (exponent_num2 == 8'd255) begin
          result = num2;
          next_state = adder_ready;
        end else begin
          next_state = adder_ready;
        end 

      end

      equalize_exponents: begin

      end
      add_mantisas: begin

      end

      normalize_number: begin

      end

      P: begin

      end
      Q: begin

      end

      AA: begin

      end 

    endcase

  end





endmodule
