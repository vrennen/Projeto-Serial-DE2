module string_transmitter(
	input i_Clk,
	input i_Rst,
	input i_txd_busy,
	input [7:0] i_rx_data,
	input i_rx_end,
	output [7:0] tx_data,
	output o_send_to_computer
);
	parameter CAPACIDADE_BYTES = 256; // qtd de characteres (bytes) que a placa vai armazenar na memoria no max
	
	logic endOfString;
	logic [7:0] caracteres [CAPACIDADE_BYTES-1:0];
	logic [9:0] index;
	logic terminarmsg;
	
	reg gotIt; // usar a logica do Serial.sv original de evitar armazenar 2x o mesmo caractere
	always@(posedge i_Clk or negedge i_Rst) begin
		if (!i_Rst) begin
			integer i;
			for (i = 0; i < CAPACIDADE_BYTES; i = i+1) begin
				caracteres[i] <= 8'h00; // zerar toda a memoria em reset assincrono
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
						caracteres[0] <= i_rx_data; // novo dado vai ser adicionado no inicio do vetor
						caracteres[CAPACIDADE_BYTES-1:1] <= caracteres[CAPACIDADE_BYTES-2:0]; // e o resto vai ser shiftado pro lado
					end
				end else begin
					caracteres = caracteres; // se nada foi adicionado, mantem tudo do jeito que tava
					gotIt = gotIt;
				end
			end else begin
				gotIt = 1'b0;
				caracteres = caracteres;
			end
		end
	end
	
	// bloco para selecionar qual byte da memoria vai ser enviado na sequencia
	// eventualmente talvez eu venha com algo mais compreensivel D:
	always@(posedge i_Clk or negedge i_Rst) begin
		if (!i_Rst) begin
			o_send_to_computer <= 1'b0;
			terminarmsg <= 1'b0;
			index <= CAPACIDADE_BYTES-1;
		end
		else begin
		// txd_busy eh uma linha do transmissor (placa->pc) que sobe quando a placa esta ocupada enviando um byte
		// esse if garante que so avanca pro prox byte quando a linha estiver disponivel
		if (!i_txd_busy && o_send_to_computer) begin
			if (index == 0) index <= CAPACIDADE_BYTES-1;
			else index <= index - 1;
		end
		// logica coisada, mas foi o que precisei fazer pra funcionar:
		// esses ifs fazem a mesma coisa: colocar cada caractere pra envio
		// nesse primeiro caso eh para o final do vetor (primeiro byte/mais antigo). Comeca o envio
		if (index==CAPACIDADE_BYTES-1) begin
			if (endOfString) begin 
				tx_data <= caracteres[CAPACIDADE_BYTES-1];
				if (terminarmsg) o_send_to_computer <= 1'b0;
				else o_send_to_computer <= 1'b1;
			end
			else begin
				terminarmsg <= 1'b0; // se ja terminou de enviar e voltou pra ca, desce o terminarmsg (explicacao abaixo)
			end
		end
		// caso para o inicio do vetor (ultimo byte/mais recente).
		// Seta terminarmsg para evitar dar loop na prox iteracao (4'b0000-4'b0001=4'b1111)
		else if (index==0) begin
			tx_data <= caracteres[0];
			terminarmsg <= 1;
		end
		// caso geral para os outros caracteres do vetor
		else begin
			tx_data <= caracteres[index];
		end
		end
	end
endmodule