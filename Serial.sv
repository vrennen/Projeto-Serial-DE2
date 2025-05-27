module Serial(
  input i_Clk, // clock do sistema
  input i_Rst_n, // reset do sistema
  input i_UART_RXD, // pino seria de recepcao (do computador para a placa)
  input i_send_data_to_host_computer,
  input [7:0] i_send_data,      // breno: byte a enviar
  output [7:0] o_received_data, // breno: byte recebido
  output o_end_of_packet,       // breno: pino de fim de byte recebido
  output o_UART_TXD, // pino serial de transmissao (da placa pro computador)
  output reg [7:0] count_data,
  output reg [31:0] buffer,
  output reg o_busy
  );
  // PARAMETRIZATION ---------------------------------------------------------
    
  parameter CLOCK_FREQUENCY = 50000000; // 50 MHz
  parameter BAUD = 115200;
  
  // Wires and Registers
  logic rx_data_ready;
  logic RxD_endofpacket;
  logic RxD_idle;
  logic [7:0] rx_data; // this is the received data, reassembled data
  logic send_byte, TxD_busy;

  
  // RECEIVER ----------------------------------------------------------------
  async_receiver #( .ClkFrequency(CLOCK_FREQUENCY), .Baud(BAUD) ) ar(
    .clk(i_Clk), // clock
    .RxD(i_UART_RXD),  // corresponde ao pino em que o dato chega serializado.
    .RxD_data_ready(rx_data_ready), // sinal que sobe quando o dado esta pronto
    .RxD_data(rx_data), // dado recebido serializado
    .RxD_endofpacket(RxD_endofpacket), // sinal que sobe quando a linha fica em standby
    .RxD_idle(RxD_idle) //pino existente mas nao usado neste exemplo.
  );
  
  
  reg gotIt; // AQUI
	
	always @ (posedge i_Clk or negedge i_Rst_n) begin
		if(!i_Rst_n) begin
			count_data = 7'h00000; 
			buffer = 32'h00000041;// note que eu mudei aqui para que o primeiro dado seja o que inicia o handshake
			gotIt = 1'b0; // AQUI
		end else begin
			if(RxD_endofpacket)begin
				if(!gotIt)begin// AQUI
					count_data = count_data + 1'b1; // soma a primeira vez que detecta a condicao
					buffer = {buffer, rx_data}; // concatena o dado que acabou de chegar ao final do buffer, descartando os que vieram antes.
					gotIt = 1'b1; // garante que na proxima nao contabiliza mais // AQUI
				end else begin// AQUI
					// enquanto o ok estiver ativo mas ja capturou o incremento, mantem tudo
					count_data = count_data;// AQUI
					buffer = buffer;
					gotIt = gotIt; // AQUI
				end// AQUI
			end else begin
				//somente quando o ok baixa eh que habilita o gotIt para pegar o proximo incremento.
				gotIt = 1'b0;// AQUI
				//e mantem o count_data como esta.
				count_data = count_data;
				buffer = buffer;
			end
		end
	end

  logic [7:0] tx_data;
  assign o_received_data = rx_data;
  assign o_end_of_packet = rx_data_ready;
  assign tx_data = i_send_data;
  //assign o_data_aux = tx_data;
  
  
  // TRANSMITTER -------------------------------------------------------------
  async_transmitter #( .ClkFrequency(CLOCK_FREQUENCY), .Baud(BAUD) ) serializer(
    .clk(i_Clk), // clock de entrada.
    .TxD(o_UART_TXD), // esse eh o pino serial, que carregara os dados de TxD_data serializados
    .TxD_start(i_send_data_to_host_computer),// indica que pode comecar a transmitir os dados de TxD_data
	 .TxD_data(tx_data), // input temporario de handshake
    .TxD_busy(o_busy) // toda transmissao deve aguardar esse pino estar em zero pra transmitir. eh um pino de saida do modulo
  );
endmodule

