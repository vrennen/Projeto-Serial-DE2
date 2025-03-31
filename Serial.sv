module Serial(
  input i_Clk, // clock do sistema
  input i_Rst_n, // reset do sistema
  input i_UART_RXD, // pino seria de recepcao (do computador para a placa)
  input i_send_data_to_host_computer,
  output o_UART_TXD, // pino serial de transmissao (da placa pro computador)
  output reg [7:0] count_data,
  output reg [31:0] buffer,
  output reg [7:0] last_tx,
  output reg eol
  );
  // PARAMETRIZATION ---------------------------------------------------------
    
  parameter CLOCK_FREQUENCY = 50000000; // 50 MHz
  parameter BAUD = 57600;
  
  // Wires and Registers
  logic rx_data_ready;
  logic RxD_endofpacket;
  logic RxD_idle;
  logic [7:0] rx_data; // this is the received data, reassembled data
  logic send_byte, TxD_busy;
  logic [7:0] tx_data;
  logic [7:0] caracteres [255:0]; // breno: 8 letras (8 bits)
  
  // RECEIVER ----------------------------------------------------------------
  async_receiver #( .ClkFrequency(CLOCK_FREQUENCY), .Baud(BAUD) ) ar(
    .clk(i_Clk), // clock
    .RxD(i_UART_RXD),  // corresponde ao pino em que o dato chega serializado.
    .RxD_data_ready(rx_data_ready), // sinal que sobre quando o dado esta pronto
    .RxD_data(rx_data), // dado recebido serializado
    .RxD_endofpacket(RxD_endofpacket), //pino existente mas nao usado neste exemplo.
    .RxD_idle(RxD_idle) //pino existente mas nao usado neste exemplo.
  );
  
  
  reg gotIt; // AQUI
  reg endOfString;
	
	always @ (posedge i_Clk or negedge i_Rst_n) begin
		if(!i_Rst_n) begin
			count_data = 7'h00000; 
			buffer = 32'h00000041;// note que eu mudei aqui para que o primeiro dado seja o que inicia o handshake
			caracteres[0] = 8'h41;
			gotIt = 1'b0; // AQUI
		end else begin
			if(RxD_endofpacket)begin
				if(!gotIt)begin// AQUI
					count_data = count_data + 1'b1; // soma a primeira vez que detecta a condicao
					buffer = {buffer, rx_data}; // concatena o dado que acabou de chegar ao final do buffer, descartando os que vieram antes.
					if (rx_data == 8'h01) begin // recebeu  caractere zero
						endOfString = 1'b1;
					end
					else begin
						endOfString = 1'b0;
						//caracteres = {caracteres, rx_data}; //breno: adicionar no 'buffer'
						caracteres[0] <= rx_data;
						caracteres[255:1] <= caracteres[254:0];
					end
					
					gotIt = 1'b1; // garante que na proxima nao contabiliza mais // AQUI
				end else begin// AQUI
					// enquanto o ok estiver ativo mas ja capturou o incremento, mantem tudo
					count_data = count_data;// AQUI
					buffer = buffer;
					gotIt = gotIt; // AQUI
					caracteres = caracteres; //breno: ???
				end// AQUI
			end else begin
				//somente quando o ok baixa eh que habilita o gotIt para pegar o proximo incremento.
				gotIt = 1'b0;// AQUI
				//e mantem o count_data como esta.
				count_data = count_data;
				buffer = buffer;
				caracteres = caracteres; //breno: ???
			end
		end
	end

	logic [9:0] index;
	logic enviando;
	logic terminarmsg;
	always@(posedge i_Clk or negedge i_Rst_n) begin
		if (!i_Rst_n) begin
			enviando <= 1'b0;
			terminarmsg <= 1'b0;
			index <= 255;
		end
		else begin
		if (!ocupado && enviando) begin
			if (index == 0) index <= 255;
			else index <= index - 1;
		end
		if (index==255) begin
			if (endOfString) begin 
				tx_data <= caracteres[255];
				if (terminarmsg) enviando <= 1'b0;
				else enviando <= 1'b1;
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
  assign last_tx = tx_data;
  assign eol = endOfString;
  //assign o_data = rx_data;
  
  //assign tx_data = data;
  //assign o_data_aux = tx_data;
  
  
  // TRANSMITTER -------------------------------------------------------------
  async_transmitter #( .ClkFrequency(CLOCK_FREQUENCY), .Baud(BAUD) ) serializer(
    .clk(i_Clk), // clock de entrada.
    .TxD(o_UART_TXD), // esse eh o pino serial, que carregara os dados de TxD_data serializados
    .TxD_start(enviando & !ocupado),// indica que pode comecar a transmitir os dados de TxD_data
	 .TxD_data(tx_data), // input temporario de handshake
    .TxD_busy(ocupado) // toda transmissao deve aguardar esse pino estar em zero pra transmitir. eh um pino de saida do modulo
  );
endmodule

