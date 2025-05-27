module string_transmitter(
	input i_Clk,
	input i_Rst,
	input i_txd_busy,
	//input i_endOfString,
	//input [7:0] caracteres [255:0],
	input [7:0] i_rx_data,
	input i_rx_end,
	output [7:0] tx_data,
	output o_send_to_computer
);
	logic endOfString;
	logic [7:0] caracteres [255:0];
	logic [9:0] index;
	//logic o_send_to_computer;
	logic terminarmsg;
	
	reg gotIt; //copiar a logica do modulo original de evitar pegar 2x o mesmo caractere
	always@(posedge i_Clk or negedge i_Rst) begin
		if (!i_Rst) begin
			integer i;
			for (i = 0; i < 256; i = i+1) begin
				caracteres[i] <= 8'h00;
			end
			gotIt = 1'b0;
		end else begin
			if (i_rx_end) begin
				if (!gotIt) begin
					gotIt = 1'b1;
					if (i_rx_data == 8'h00) begin
						endOfString = 1'b1;
					end else begin
						endOfString = 1'b0;
						caracteres[0] <= i_rx_data;
						caracteres[255:1] <= caracteres[254:0];
					end
				end else begin
					caracteres = caracteres;
					gotIt = gotIt;
				end
			end else begin
				gotIt = 1'b0;
				caracteres = caracteres;
			end
		end
	end
	
	always@(posedge i_Clk or negedge i_Rst) begin
		if (!i_Rst) begin
			o_send_to_computer <= 1'b0;
			terminarmsg <= 1'b0;
			index <= 255;
		end
		else begin
		if (!i_txd_busy && o_send_to_computer) begin
			if (index == 0) index <= 255;
			else index <= index - 1;
		end
		if (index==255) begin
			if (endOfString) begin 
				tx_data <= caracteres[255];
				if (terminarmsg) o_send_to_computer <= 1'b0;
				else o_send_to_computer <= 1'b1;
			end
			else begin
				terminarmsg <= 1'b0;
			end
		end
		else if (index==0) begin
			tx_data <= caracteres[0];
			terminarmsg <= 1;
		end
		else begin
			tx_data <= caracteres[index];
		end
		end
	end
  //assign last_tx = tx_data;
  //assign eol = endOfString;
endmodule