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

  enum{
    ADDER_READY,
    READ_IN1,
    READ_IN2,
    CHECK_ESPECIAL_CASES,
    EQUALIZE_EXPONENTS,
    ADD_MANTISAS,
    NORMALIZE_NUMBER,
    BUILD_NUMBER,
    RETURN_NUM1,
    RETURN_NUM2,
    RETURN_NAN
  }present_state, next_state;

    always_ff @(posedge clock, negedge nreset) begin : SEQ
    if (~nreset)begin
        present_state <= ADDER_READY;
    end
    else begin      
        present_state <= next_state;
    end
  end

  always_comb begin : COM
    
    case(present_state)

    ADDER_READY: begin
        next_state = READ_IN1;
    end
    READ_IN1: begin
        next_state = READ_IN2;
    end
    READ_IN2: begin
        next_state = CHECK_ESPECIAL_CASES;
    end
    CHECK_ESPECIAL_CASES: begin
        next_state = EQUALIZE_EXPONENTS;
        if(exponent_num1 == 8'd255 && mantissa_num1 == 8'd0) next_state = RETURN_NUM1;
        if(exponent_num2 == 8'd255 && mantissa_num2 == 8'd0) next_state = RETURN_NUM2;

        if(exponent_num1 == 8'd0 && mantissa_num1 == 8'd0) next_state = RETURN_NUM2;
        if(exponent_num1 == 8'd255 && mantissa_num1 != 8'd0) next_state = RETURN_NAN;

        if(exponent_num2 == 8'd0 && mantissa_num2 == 8'd0) next_state = RETURN_NUM1;
        if(exponent_num2 == 8'd255 && mantissa_num2 != 8'd0) next_state = RETURN_NAN;

        if(exponent_num1 == 8'd255 && mantissa_num1 == 8'd0 && exponent_num2 == 8'd255 && mantissa_num2 == 8'd0) begin
            if (sign_num1 == sign_num2) next_state = RETURN_NUM1;
            else next_state = RETURN_NAN;
        end 
        
        
    end
    EQUALIZE_EXPONENTS: begin
        next_state = ADD_MANTISAS;
    end
    ADD_MANTISAS: begin
        next_state = NORMALIZE_NUMBER;
    end
    NORMALIZE_NUMBER: begin
        next_state = BUILD_NUMBER;
    end
    BUILD_NUMBER: begin
        next_state = ADDER_READY;
    end
    RETURN_NUM1: begin
        next_state = ADDER_READY;
    end
    RETURN_NUM2: begin
        next_state = ADDER_READY;
    end
    RETURN_NAN: begin
        next_state = ADDER_READY;
    end


    endcase
  end

  always_ff @( posedge clock ) begin : LOG
    case(present_state)
        ADDER_READY: begin
            ready <= '1;
        end
        READ_IN1: begin
            ready <= '0;
            num1 <= a;
            sign_num1 <= a[15];
            exponent_num1 <= a[14:7];
            mantissa_num1 <= a[6:0];
        end
        READ_IN2: begin
            num2 <= b;
            sign_num2 <= b[15];
            exponent_num2 <= b[14:7];
            mantissa_num2 <= b[6:0];
        end
        CHECK_ESPECIAL_CASES: begin
            if(exponent_num1 == 8'd0 && mantissa_num1 != 8'd0) mantissa_num1_aux <= {1'b0, mantissa_num1};
            else mantissa_num1_aux <= {1'b1, mantissa_num1};
            if(exponent_num2 == 8'd0 && mantissa_num2 != 8'd0) mantissa_num2_aux <= {1'b0, mantissa_num2};
            else mantissa_num2_aux <= {1'b1, mantissa_num2};
        end
        EQUALIZE_EXPONENTS: begin
            if (exponent_num1 < exponent_num2) begin 
                mantissa_num1_aux <= mantissa_num1_aux>>(exponent_num2-exponent_num1);
                exponent_num1 <= exponent_num2;
            end
            else if(exponent_num2<exponent_num1)begin
                mantissa_num2_aux <= mantissa_num2_aux>>(exponent_num1-exponent_num2);
                exponent_num2 <= exponent_num1;
            end
            
        end
        ADD_MANTISAS: begin
            exponent_sum <= exponent_num1;
            if(sign_num1 == sign_num2)begin
                mantissa_sum_aux <= mantissa_num1_aux + mantissa_num2_aux;
                sign_sum <= sign_num1;
            end
            else begin
                if(mantissa_num1_aux < mantissa_num2_aux) begin
                    mantissa_sum_aux <= mantissa_num2_aux - mantissa_num1_aux;
                    sign_sum <= sign_num2;
                end else begin
                    mantissa_sum_aux <= mantissa_num1_aux - mantissa_num2_aux;
                    sign_sum <= sign_num1;
                end
            end
            
        end
        NORMALIZE_NUMBER: begin
        if (mantissa_sum_aux[8] == '1) begin
          mantissa_sum_aux <= mantissa_sum_aux >>1;
          exponent_sum <= exponent_sum +1'b1;
        end

        if (mantissa_sum_aux[7] != 1) begin
            if (mantissa_sum_aux[6]) begin   
                mantissa_sum_aux <= mantissa_sum_aux <<1;
                exponent_sum <= exponent_sum - 1'd1;
            end else if (mantissa_sum_aux[5]) begin
                mantissa_sum_aux <= mantissa_sum_aux <<2;
                exponent_sum <= exponent_sum -2'd2;
            end else if (mantissa_sum_aux[4]) begin
                mantissa_sum_aux <= mantissa_sum_aux <<3;
                exponent_sum <= exponent_sum -2'd3;
            end else if (mantissa_sum_aux[2]) begin
                mantissa_sum_aux <= mantissa_sum_aux <<4;
                exponent_sum <= exponent_sum -3'd4;
            end else if (mantissa_sum_aux[1]) begin   
                mantissa_sum_aux <= mantissa_sum_aux <<5;
                exponent_sum <= exponent_sum -3'd5;
            end else if (mantissa_sum_aux[0]) begin
                mantissa_sum_aux <= mantissa_sum_aux <<6;
                exponent_sum <= exponent_sum -3'd6;
            end else begin
                exponent_sum <= '0;
                mantissa_sum_aux <= '0;
            end
        end
        end
        BUILD_NUMBER: begin
            sum <= {sign_sum, exponent_sum, mantissa_sum_aux[6:0]};
            $display("sum %b", sum);
        end

        RETURN_NUM1: begin
            sum <= num1;
            $display("sum %b", sum);
        end
        RETURN_NUM2: begin
            sum <= num2;
            $display("sum %b", sum);
        end
        RETURN_NAN: begin
            sum <= {1'b0, 8'd255, 7'b1};;
            $display("sum %b", sum);
        end

    endcase   
    
  end



endmodule



