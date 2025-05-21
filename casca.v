module casca(
	input CLOCK_50,
	input [3:0] KEY,
	input [1:0] SW,
	input UART_RXD,
	output UART_TXD,
	output [17:0] LEDR, // vai apresentar a quantidade de dados recebidos do computador
	// nesse exemplo, cada par de displays vai apresentar o hexadecimal do caractere recebido.
	// a cada novo caractere, os anteriores sao shiftados para a esquerda.
	output [6:0] HEX0, 
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7
);

  //wire [7:0] recebido;
  //wire [7:0] letra;
  wire ocupado;
  //wire endOfString;
  //wire char;
  wire send_computer;
  wire [7:0] send_char;
  //wire [7:0] caracteres [255:0];
  wire [7:0] received_char;
  wire rx_end;
  
  string_transmitter transmissao(
	 .i_Clk(CLOCK_50),
	 .i_Rst(KEY[0]),
	 .i_txd_busy(ocupado),
	 .i_rx_data(received_char),
	 .i_rx_end(rx_end),
	 //.i_endOfString(endOfString),
	 //.caracteres(caracteres),
	 .tx_data(send_char),
	 .o_send_to_computer(send_computer)
	 );
  
  Serial echo(
    .i_Clk(CLOCK_50),
    .i_Rst_n(KEY[0]),
    .i_UART_RXD(UART_RXD),
	 .i_send_data_to_host_computer(send_computer), // invertido pela natureza default do KEY na DE2
	 .i_send_data(send_char),
	 .o_received_data(received_char),
	 .o_end_of_packet(rx_end),
    .o_UART_TXD(UART_TXD),
	 .count_data(count_data),
	 .buffer(binNumber),
	 //.caracteres(caracteres),
	 //.last_tx(),
	 //.endOfString(endOfString),
	 .o_busy(ocupado)
  );
  
  
  wire [31:0] binNumber;
  wire [7:0] count_data;
  assign LEDR[7:0] = count_data;
  //assign LEDR[16:9] = letra;
  
  SEG7_LUT_8 sl_1(	HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7,binNumber);

endmodule 