module bfloat16_adder (
    output logic [15:0] sum,
    output logic ready,
    input logic [15:0] a,
    b,
    input logic clock,
    nreset
);

  logic sign_num1, sign_num2, sign_sum;
  
  logic [7:0] exponent_num1, exponent_num2, exponent_sum;
  logic [6:0] mantissa_num1, mantissa_num2;
  logic [8:0] mantissa_sum;

  logic [15:0] num1, num2;
  logic [15:0] final_result, result;
  

  logic [7:0] mantissa_num1_aux, mantissa_num2_aux;
  logic [9:0] mantissa_sum_aux;



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
    normalize_bigger_number, 
    normalize_smaller_number,
    build_number
  } present_state, next_state;


  always_ff @(posedge clock, negedge nreset) begin : SEQ
    if (~nreset) begin 
      present_state <= adder_ready;

    end
    else begin
      present_state <= next_state;
      sum <= result;
    end
  end


  always_comb begin : COM

    num1 = '0;
    sign_num1 = '0;
    exponent_num1 = '0;
    mantissa_num1 = '0;
    num2 = '0;
    sign_num2 = '0;
    exponent_num2 = '0;
    mantissa_num2 = '0;
    mantissa_num1_aux = '0;
    mantissa_num2_aux = '0;
    exponent_sum = '0;
    mantissa_sum_aux = '0;
    sign_sum = '0;
    final_result = '0;

    case (present_state)
      
      adder_ready: begin
        //ready = 1'b1;
        //sum = sum;
        next_state = reading_first_input;
      end

      reading_first_input: begin
        //Read Input A
        //ready = 1'b0;
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
        final_result =  num2;
        next_state = adder_ready;
      end

      num1_almost_zero: begin
        mantissa_num1_aux = {1'b0, mantissa_num1};
        next_state = checking_zero_exp_num2;
      end

      checking_zero_exp_num2: begin
        if (exponent_num2 == 8'd0) begin
          if (mantissa_num2 == 7'd0) begin
            next_state = num2_zero;
          end else begin
            next_state = num2_almost_zero;
          end
        end else begin
          mantissa_num2_aux = {1'b1, mantissa_num2};
          next_state = checking_255_exp_num1;
        end 
      end

      num2_zero: begin
        final_result = num1;
        next_state = adder_ready;
      end 

      num2_almost_zero: begin
        mantissa_num2_aux = {1'b0, mantissa_num2};
        next_state = checking_255_exp_num1;
      end 

      checking_255_exp_num1: begin
        
        if (exponent_num1 == 8'd255) begin
          if (mantissa_num1 == '0) begin
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
          if (mantissa_num2 == '0) begin
            if (sign_num1 == sign_num2) final_result = num1; 
            else final_result = {sign_num1, 8'd255, 7'b1};
          end else begin
            final_result = num2;
          end
        end else begin
          final_result = num1;
        end 
        next_state = adder_ready;
      end 

      num1_Nan : begin
        final_result = num1;
        next_state = adder_ready;
      end

      checking_255_exp_num2: begin
        
        if (exponent_num2 == 8'd255) begin
          $display("inf or nan %d", exponent_num2);
          final_result = num2;
          next_state = adder_ready;
        end else begin
          next_state = equalize_exponents;
        end 
      end

      equalize_exponents: begin
       

        if (exponent_num1 < exponent_num2) begin 
        mantissa_num1_aux = mantissa_num1_aux>>(exponent_num2-exponent_num1);
        exponent_num1 = exponent_num2;
        end
        else if(exponent_num2<exponent_num1)begin
        mantissa_num2_aux = mantissa_num2_aux>>(exponent_num1-exponent_num2);
        exponent_num2 = exponent_num1;
        end
 
        next_state = add_mantisas;
      end


      add_mantisas: begin
        //Probablemente este mal
        // primero voy a asumir que los dos son positivos

        if(sign_num1 == sign_num2)begin
          
          mantissa_sum_aux = mantissa_num1_aux + mantissa_num2_aux;
          
          sign_sum = sign_num1;
        end
        else begin
          
          if(mantissa_num1_aux < mantissa_num2_aux) begin
            mantissa_sum_aux = mantissa_num2_aux - mantissa_num1_aux;
            sign_sum = sign_num2;
          end else begin
            mantissa_sum_aux = mantissa_num1_aux - mantissa_num2_aux;
            sign_sum = sign_num1;
          end
        end
        


        
        exponent_sum = exponent_num1;
        


      next_state = normalize_bigger_number;

      end

      normalize_bigger_number: begin

        if (mantissa_sum_aux[8] == 1) begin
           
          mantissa_sum_aux = mantissa_sum_aux >>1;
          exponent_sum = exponent_sum +1'b1;
        end

        

        if (mantissa_sum_aux[7] != 1) begin
          next_state = normalize_smaller_number;
        end else 
        next_state = build_number;

        

      end

      normalize_smaller_number: begin

        if (mantissa_sum_aux[6]) begin    // Check highest priority input
          mantissa_sum_aux = mantissa_sum_aux <<1;
          exponent_sum = exponent_sum - 1'd1;
        end else if (mantissa_sum_aux[5]) begin
            mantissa_sum_aux = mantissa_sum_aux <<2;
          exponent_sum = exponent_sum -2'd2;
        end else if (mantissa_sum_aux[4]) begin
            mantissa_sum_aux = mantissa_sum_aux <<3;
          exponent_sum = exponent_sum -2'd3;
        end else if (mantissa_sum_aux[2]) begin
           mantissa_sum_aux = mantissa_sum_aux <<4;
          exponent_sum = exponent_sum -3'd4;
        end else if (mantissa_sum_aux[1]) begin    // Check highest priority input
            mantissa_sum_aux = mantissa_sum_aux <<5;
          exponent_sum = exponent_sum -3'd5;
        end else if (mantissa_sum_aux[0]) begin
          mantissa_sum_aux = mantissa_sum_aux <<6;
          exponent_sum = exponent_sum -3'd6;
        end else begin
          exponent_sum = '0;
          mantissa_sum_aux = '0;
        end

        next_state = build_number;
          
      end
      build_number: begin
        final_result = {sign_sum, exponent_sum, mantissa_sum_aux[6:0]};
        $display("final_result %b", final_result);
        next_state = adder_ready;

      end

      default: begin
        next_state = adder_ready;
      end


    endcase

  if(next_state == adder_ready) begin 
    //ready = '1;
    result = final_result;
  end else begin
    //ready = '0;
    result = sum;
  end

  if(present_state == adder_ready) begin 
    ready = '1;
    //result = final_result;
  end else begin
    ready = '0;
    //result = sum;
  end


  end



endmodule