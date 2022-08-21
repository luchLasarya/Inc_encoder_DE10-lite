module inc_enc_to_sevseg
	(
		input MAX10_CLK1_50,
		input in1,in2,
		input rst_n,
		output [7 : 0] deg0, deg1
	);
	
	wire[7 : 0] value;
	wire v;
	assign v = 1'b0;
	
	inc_enc_debounced #(16, 5000) encoder 
		(
			.clk(MAX10_CLK1_50),
			.in1(in1),
			.in2(in2),
			.rst_n(rst_n),
			.value(value)
		);
		
	sev_seg sev_seg0
		(
			.dp(v),
			.in(value[3 : 0]),
			.out(deg0)
		);
		
	sev_seg sev_seg1
		(
			.dp(v),
			.in(value[7 : 4]),
			.out(deg1)
		);


endmodule //inc_enc_to_sevseg


module inc_enc_debounced
	#(
		parameter WIDTH = 8,  // Разрядность
		parameter DIV = 5000	//Делитель частоты = тактовая частота * длительность дребезга
	)
	(
		input clk,
		input in1, in2,
		input rst_n,
		output [WIDTH-1 : 0] value
	);
	
	wire eck; //тактирование энкодера для фильтрации дребезга
	
	reg s1, s2;
	
	freq_divider #(DIV) freq_divider // Подключаем делитель частоты
		(
			.clk_in(clk),
			.rst_n (rst_n),
			.clk_out (eck)
		);
	
	always @(posedge eck)   // Формируем новый сигнал без дребезга
		begin
			if	(in1)	s1 <= 1'b1;
			else		s1 <= 1'b0;
			if	(in2)	s2 <= 1'b1;
			else		s2 <= 1'b0;
		end
	
	inc_enc #(WIDTH) encoder  // Это энкодер без подавления дребезга, подаем на него новый сигнал
		(
			.in1(s1),
			.in2(s2),
			.rst_n(rst_n),
			.value(value)
		);

	
endmodule //inc_enc_debounced




module freq_divider
	#(
		parameter DIV_CNT = 8,       
		parameter WIDTH = $clog2(DIV_CNT)
	)
	(
		input clk_in,
		input rst_n,
		output clk_out
		
	);
	
	reg [WIDTH-1 : 0] cnt;
	
	always @(posedge clk_in or negedge rst_n)
		begin
			if (!rst_n)
				cnt <= {WIDTH{1'b0}};
			else if (cnt == DIV_CNT-1)
				cnt <= {WIDTH{1'b0}};
			else
				cnt <= cnt + 1'b1;
		end
	
	assign clk_out = (cnt == 0) ? 1'b1 : 1'b0;

endmodule //freq_divider



module inc_enc 
	# ( parameter WIDTH = 8)
	(
		input in1,in2,
		input rst_n,
		output reg [WIDTH-1 : 0] value
	);
	
	always @(posedge in1 or  negedge rst_n)
		begin
			if (~rst_n) value <= {WIDTH{1'b0}};
			else value <= (in2 == 1'b1) ? (value + 1'b1) : (value - 1'b1);
		end
		
endmodule // inc_enc

	
	
	
	



module sev_seg
 (
	input dp,
	input [3 : 0] in,
	output reg [7 : 0] out
 );
 
	always@(*)
		begin // у индикатора инверсные входы!
			case (in)
				4'b0000 : out[6 : 0] = 7'b1000000; // 0  
				4'b0001 : out[6 : 0] = 7'b1111001; // 1
				4'b0010 : out[6 : 0] = 7'b0100100; // 2
				4'b0011 : out[6 : 0] = 7'b0110000; // 3
				4'b0100 : out[6 : 0] = 7'b0011001; // 4
				4'b0101 : out[6 : 0] = 7'b0010010; // 5
				4'b0110 : out[6 : 0] = 7'b0000010; // 6
				4'b0111 : out[6 : 0] = 7'b1111000; // 7
				4'b1000 : out[6 : 0] = 7'b0000000; // 8
				4'b1001 : out[6 : 0] = 7'b0010000; // 9
				4'b1010 : out[6 : 0] = 7'b0001000; // A
				4'b1011 : out[6 : 0] = 7'b0000011; // b(B)
				4'b1100 : out[6 : 0] = 7'b1000110; // C
				4'b1101 : out[6 : 0] = 7'b0100001; // d(D)
				4'b1110 : out[6 : 0] = 7'b0000110; // E
				4'b1111 : out[6 : 0] = 7'b0001110; // F
				default : out[6 : 0] = 7'b1111111; //ничего
			endcase
					
			if (dp) out[7] = 1'b0;
			else out[7] = 1'b1;  //decimal point	
		end

		
endmodule
