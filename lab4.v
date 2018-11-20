`define tamanho_barramento 70

// flag no barramento_entrada
`define modo_cache        0
`define modo_memoria     10
`define modo_cpu         20
`define modo_snooping    50
`define rfo              51
`define write_back       70

// estado do bloco de cache
`define INVALIDO      2'b00
`define MODIFICADO    2'b01
`define COMPARTILHADO 2'b10
`define EXCLUSIVO     2'b11

// resultado de operacao da CPU
`define CPU_READ_MISS  2'b00
`define CPU_READ_HIT   2'b01
`define CPU_WRITE_MISS 2'b10
`define CPU_WRITE_HIT  2'b11

// mensagem no barramento_entrada
`define WRITE_MISS_ON_BUS          2'b00
`define READ_MISS_ON_BUS           2'b01
`define INVALIDATE_ON_BUS          2'b10
`define WRITE_BACK_BLOCK_ON_BUS    2'b11



/* MODULO TOP-LEVEL*/
module lab4();

  	reg  [`tamanho_barramento:0]barramento_entrada;
	wire  [`tamanho_barramento:0]barramento_saida;

	initial begin

		/*   ESTADO INICIAL INVALIDO*/
		#1 
			/* 
				CPU WRITE MISS
				estado invalido do bloco
			 */
			barramento_entrada[6:0] = {2'b00,2'b00,1'b1,1'b0,1'b1};	
			$display("input :%b",barramento_entrada);
		#1
			$display("output:%b\n",barramento_saida);

		#1 
			/* 
				CPU WRITE MISS
				estado invalido do bloco
			 */
			barramento_entrada[6:0] = {2'b00,2'b00,1'b0,1'b0,1'b1};	
			$display("input :%b",barramento_entrada);
		#1
			$display("output:%b\n",barramento_saida);



		/*   ESTADO INICIAL COMPARTILHADO*/
		#1 
			/* 
				CPU WRITE MISS
				estado invalido do bloco
			 */
			barramento_entrada[6:0] = {2'b00,2'b00,1'b1,1'b0,1'b1};	
			$display("input :%b",barramento_entrada);
		#1
			$display("output:%b\n",barramento_saida);

		#1 
			/* 
				CPU WRITE MISS
				estado invalido do bloco
			 */
			barramento_entrada[6:0] = {2'b00,2'b00,1'b0,1'b0,1'b1};	
			$display("input :%b",barramento_entrada);
		#1
			$display("output:%b\n",barramento_saida);
			

		$finish;
   	end
	snooping_executa maquina1(barramento_entrada,barramento_saida);
endmodule



/***************************************************** modulo que implementa a maquina snooping que executa*************************************/
module snooping_executa(barramento_entrada,barramento_saida);

	output reg [`tamanho_barramento:0]barramento_saida;
	input 	   [`tamanho_barramento:0]barramento_entrada;
	reg        [`tamanho_barramento:0]buffer;

	always@(barramento_entrada) begin
		/* verifica se a mensagem no barramento esta em modo de cache */
		buffer = barramento_entrada;
		if(buffer[`modo_cache] == 1'b1)begin
			/* o case avalia em qual estado o bloco da cache esta */
			case(buffer[4:3])
				`INVALIDO:
					begin
						if(buffer[2:1] === `CPU_READ_MISS)begin
							/* muda de estado para compartilhado*/
							buffer[53:52] = `COMPARTILHADO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/*  place read miss on bus */
							buffer[61:60] = `READ_MISS_ON_BUS;
							/* caches focos do place on bus */
							buffer[64:62] = 3'b111;
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
						end else if(buffer[2:1] === `CPU_WRITE_MISS)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] =  `EXCLUSIVO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/*  place write miss on bus */
							buffer[61:60] = `WRITE_MISS_ON_BUS;
							/* caches focos do place on bus */
							buffer[64:62] = 3'b111;
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
						end

						/*  
							tira referencia da cpu   
						*/
						buffer[`modo_cpu]       = 1'b0;
					end
				`MODIFICADO:
					begin
						/* 
							o bloco continuara no estado modificado independentemente
						*/
						buffer[53:52] = `MODIFICADO;
						/* liga o modo de controlador snooping*/
						buffer[50] = 1'b1;
						/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;

						/*  
							tira referencia da cpu   
						*/
						buffer[`modo_cpu]       = 1'b0;
					end


				`COMPARTILHADO:
					begin
						if(barramento_entrada[2:1] === `CPU_READ_MISS)begin
							/* se mantem no estado compartilhado*/
							buffer[53:52] = `COMPARTILHADO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/* place read miss on bus*/
							buffer[61:60] = `READ_MISS_ON_BUS;
							/* caches focos do place on bus */
							buffer[64:62] = 3'b111;
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
						end else if(barramento_entrada[2:1] === `CPU_READ_HIT)begin
							/* se mantem no estado compartilhado*/
							buffer[53:52] = `COMPARTILHADO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
						end else if(barramento_entrada[2:1] === `CPU_WRITE_HIT)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] = `EXCLUSIVO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/* place invalidate miss on bus*/
							buffer[61:60] = `INVALIDATE_ON_BUS;
							/* caches focos do place on bus */
							buffer[64:62] = 3'b111;
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
						end else if(barramento_entrada[2:1] === `CPU_WRITE_MISS)begin
							/* muda de estado para exclusivo*/
							buffer[53:52] = `EXCLUSIVO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/* place write miss on bus*/
							buffer[61:60] = `WRITE_MISS_ON_BUS;
							/* caches focos do place on bus */
							buffer[64:62] = 3'b111;
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
						end

						/*  
							tira referencia da cpu   
						*/
						buffer[`modo_cpu]       = 1'b0;

					end


				`EXCLUSIVO:
					begin
						if(barramento_entrada[2:1] === `CPU_READ_MISS)begin
							/* muda de estado para compartilhado*/
							buffer[53:52] = `COMPARTILHADO;
							/* liga o modo de controlador snooping*/
							buffer[50] = 1'b1;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* place read miss on bus*/
							buffer[61:60] = `READ_MISS_ON_BUS;
							/* caches focos do place on bus */
							buffer[64:62] = 3'b111;
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
							/* indica o write back */
							buffer[`write_back] = 1'b1;
						end else if(barramento_entrada[2:1] === `CPU_READ_HIT)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `MODIFICADO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
							/* zera a flag de write back */
							buffer[`write_back] = 1'b0;
						end else if(barramento_entrada[2:1] === `CPU_WRITE_HIT)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `MODIFICADO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
							/* seta flag de write back */
							buffer[`write_back] = 1'b0;
						end else if(barramento_entrada[2:1] === `CPU_WRITE_MISS)begin
							/* se mantem no estado exclusivo*/
							buffer[53:52] = `MODIFICADO;
							/* registra referencia para o controlador snooping*/
							buffer[`modo_snooping]  = 1'b1;
							/* cache foco do snooping*/
							buffer[55:54] = buffer[6:5];
							/* endereco de bloco*/
							buffer[68:65] = buffer[49:46];
							/* seta flag de write back */
							buffer[`write_back] = 1'b0;
						end

						/*  
							tira referencia da cpu   
						*/
						buffer[`modo_cpu]       = 1'b0;
					end
				default:
					begin 
						/* tira todas as referencias */
						buffer[`modo_snooping]     = 1'b0;
						buffer[`modo_cpu]       = 1'b0;
						buffer[`modo_memoria]   = 1'b0;
						buffer[`modo_cache]     = 1'b0;
					end
			endcase	
		end
		barramento_saida = buffer;
	end
endmodule


/****************************************modulo que implementa a maquina snooping que escuta****************************************/
module snooping_escuta(estado_inicial,estado_final,barramento_entrada,barramento_saida);
	output reg [`tamanho_barramento:0] barramento_saida;
	output reg [1:0]estado_final;
	input [`tamanho_barramento:0]barramento_entrada;
	input [1:0]estado_inicial;

	reg [`tamanho_barramento:0]buffer;
	reg [1:0]buffer_de_estado;
	always@(barramento_entrada)begin
		buffer = barramento_entrada;
		/* o case avalia em qual estado o bloco da cache esta */
		case(estado_inicial)
			`INVALIDO:
				begin
					/* 
						no estado invalido independente do que seja escutado
						no barramento_entrada, o bloco continuara no estado invalido
					*/

					buffer_de_estado = `INVALIDO;
						/*  
							tira referencia do modo snooping
						*/
						buffer[`modo_snooping] = 1'b0;
					
				end

			`MODIFICADO:
				begin
					/* 
						no estado modificado, semelhante ao que 
						acontece no estado invalido,
						independente do que seja escutado
						no barramento_entrada, o bloco continuara no estado modificado
					*/
					buffer_de_estado = `MODIFICADO;

					/*  
							tira referencia do modo snooping
					*/
					buffer[`modo_snooping] = 1'b0;


				end


			`COMPARTILHADO:
				begin
					if(buffer[61:60] === `READ_MISS_ON_BUS)begin
						buffer_de_estado = `COMPARTILHADO;
					end else if(buffer[61:60] === `WRITE_MISS_ON_BUS )begin
						buffer_de_estado = `INVALIDO;
					end else if(buffer[61:60] === `INVALIDATE_ON_BUS)begin
						buffer_de_estado = `INVALIDO;
					end else if(buffer[61:60] === `WRITE_BACK_BLOCK_ON_BUS)begin
						/* nao faz nada */
					end

					/*  
						tira referencia do modo snooping
					*/
					buffer[`modo_snooping] = 1'b0;
				end


			`EXCLUSIVO:
				begin
					if(buffer[61:60] === `READ_MISS_ON_BUS)begin
						buffer_de_estado = `COMPARTILHADO;
						/* abort memory access */
						buffer[`rfo]  = 1'b1;
						/* write back block */  
						buffer[`write_back] = 1'b1;
					end else if(buffer[61:60] === `WRITE_MISS_ON_BUS)begin
						buffer_de_estado = `INVALIDO;
						/* abort memory access */
						buffer[`rfo]  = 1'b1; 
						/* write back block */  
						buffer[`write_back] = 1'b1;
					end else if(buffer[61:60] === `INVALIDATE_ON_BUS)begin
						/* nao faz nada */
					end else if(buffer[61:60] === `WRITE_BACK_BLOCK_ON_BUS)begin
						/* nao faz nada */
					end

					/*  
						tira referencia do modo snooping
					*/
					buffer[`modo_snooping] = 1'b0;

				end
			default:
				begin
					/* tira todas as referencias */
					buffer[`modo_snooping]     = 1'b0;
					buffer[`modo_cpu]       = 1'b0;
					buffer[`modo_memoria]   = 1'b0;
					buffer[`modo_cache]     = 1'b0;
				end
		endcase
		estado_final = buffer_de_estado;
		barramento_saida = buffer;
	end
endmodule



/* modulo para simular na placa*/

// module lab4(SW,LEDR,KEY,HEX0,HEX1,HEX3,HEX4,HEX5,HEX6,HEX7);
// 	input [17:0]SW;
// 	input [3:0]KEY;
// 	output [0:6]HEX0;
// 	output [0:6]HEX1;
// 	output [0:6]HEX3;
// 	output [0:6]HEX4;
// 	output [0:6]HEX5;
// 	output [0:6]HEX6;
// 	output [0:6]HEX7;
// 	output [17:0]LEDR;
	
	

// 	wire [`tamanho_barramento:0]linha_entrada;
// 	wire [`tamanho_barramento:0]linha_saida;
	
// 	display7 f(dirty,HEX0);
// 	display7 r(lru,HEX1);
// 	display7 t(status,HEX3);
	
// 	display7 y({3'b000,SW[17]},HEX5);
// 	display7 p(SW[16:13],HEX4);
	
// 	display7 e(saida[7:4],HEX7);
// 	display7 d(saida[3:0],HEX6);
	
// endmodule


// /* Display de 7 segmentos */
// module display7(Entrada,SaidaDisplay);
//   input [3:0] Entrada;
//   output reg [0:6] SaidaDisplay;
// //      0
// //     ---
// //  5 |   | 1
// //     --- <--6
// //  4 |   | 2
// //     ---
// //      3

// //xxx:SaidaDisplay=YYYYYYY, caso a entrada seja igual ao XXX,a saida do display e YYY(representacao da entrada na placa
// //conforme o desenho acima),0 significa traco ligado e 1 significa traco desligado.
// //para formar o 0,por exemplo,os tracos 0,1,2,3,4,5 ficam ligados, e o 6 desligado,logo =7'b0000001
//   always begin
//     case(Entrada)

//       0:SaidaDisplay=7'b0000001; //0
//       1:SaidaDisplay=7'b1001111; //1
//       2:SaidaDisplay=7'b0010010; //2
//       3:SaidaDisplay=7'b0000110; //3
//       4:SaidaDisplay=7'b1001100; //4
//       5:SaidaDisplay=7'b0100100; //5
//       6:SaidaDisplay=7'b0100000; //6
//       7:SaidaDisplay=7'b0001111; //7
//       8:SaidaDisplay=7'b0000000; //8
//       9:SaidaDisplay=7'b0001100; //9
//       10:SaidaDisplay=7'b0001000;//A
//       11:SaidaDisplay=7'b1100000;//B
//       12:SaidaDisplay=7'b0110001;//C
//       13:SaidaDisplay=7'b1000010;//D
//       14:SaidaDisplay=7'b0110000;//E
//       15:SaidaDisplay=7'b0111000;//F
//     endcase
//   end
// endmodule