// auto-generated by bsg_ascii_to_rom.py from /home/petrisko/bitbucket/bp_be/tb/asm/rv64ui_p_example.bin; do not modify
//
//rv64ui_p_example.riscv:     file format elf64-littleriscv
//
//
//Disassembly of section .text.init:
//
//0000000080000000 <_start>:
//    80000000:	04c0006f          	jal	x0,8000004c <reset_vector>
//
//0000000080000004 <trap_vector>:
//    80000004:	34202f73          	csrrs	x30,mcause,x0
//    80000008:	00800f93          	addi	x31,x0,8
//    8000000c:	03ff0a63          	beq	x30,x31,80000040 <write_tohost>
//    80000010:	00900f93          	addi	x31,x0,9
//    80000014:	03ff0663          	beq	x30,x31,80000040 <write_tohost>
//    80000018:	00b00f93          	addi	x31,x0,11
//    8000001c:	03ff0263          	beq	x30,x31,80000040 <write_tohost>
//    80000020:	80000f17          	auipc	x30,0x80000
//    80000024:	fe0f0f13          	addi	x30,x30,-32 # 0 <_start-0x80000000>
//    80000028:	000f0463          	beq	x30,x0,80000030 <trap_vector+0x2c>
//    8000002c:	000f0067          	jalr	x0,0(x30)
//    80000030:	34202f73          	csrrs	x30,mcause,x0
//    80000034:	000f5463          	bge	x30,x0,8000003c <handle_exception>
//    80000038:	0040006f          	jal	x0,8000003c <handle_exception>
//
//000000008000003c <handle_exception>:
//    8000003c:	539e6e13          	ori	x28,x28,1337
//
//0000000080000040 <write_tohost>:
//    80000040:	00001f17          	auipc	x30,0x1
//    80000044:	fdcf2023          	sw	x28,-64(x30) # 80001000 <tohost>
//    80000048:	ff9ff06f          	jal	x0,80000040 <write_tohost>
//
//000000008000004c <reset_vector>:
//    8000004c:	f1402573          	csrrs	x10,mhartid,x0
//    80000050:	00051063          	bne	x10,x0,80000050 <reset_vector+0x4>
//    80000054:	00000297          	auipc	x5,0x0
//    80000058:	01028293          	addi	x5,x5,16 # 80000064 <reset_vector+0x18>
//    8000005c:	30529073          	csrrw	x0,mtvec,x5
//    80000060:	18005073          	csrrwi	x0,satp,0
//    80000064:	00000297          	auipc	x5,0x0
//    80000068:	01c28293          	addi	x5,x5,28 # 80000080 <reset_vector+0x34>
//    8000006c:	30529073          	csrrw	x0,mtvec,x5
//    80000070:	fff00293          	addi	x5,x0,-1
//    80000074:	3b029073          	csrrw	x0,pmpaddr0,x5
//    80000078:	01f00293          	addi	x5,x0,31
//    8000007c:	3a029073          	csrrw	x0,pmpcfg0,x5
//    80000080:	00000297          	auipc	x5,0x0
//    80000084:	01828293          	addi	x5,x5,24 # 80000098 <reset_vector+0x4c>
//    80000088:	30529073          	csrrw	x0,mtvec,x5
//    8000008c:	30205073          	csrrwi	x0,medeleg,0
//    80000090:	30305073          	csrrwi	x0,mideleg,0
//    80000094:	30405073          	csrrwi	x0,mie,0
//    80000098:	00000e13          	addi	x28,x0,0
//    8000009c:	00000297          	auipc	x5,0x0
//    800000a0:	f6828293          	addi	x5,x5,-152 # 80000004 <trap_vector>
//    800000a4:	30529073          	csrrw	x0,mtvec,x5
//    800000a8:	00100513          	addi	x10,x0,1
//    800000ac:	01f51513          	slli	x10,x10,0x1f
//    800000b0:	02055c63          	bge	x10,x0,800000e8 <reset_vector+0x9c>
//    800000b4:	0ff0000f          	fence	iorw,iorw
//    800000b8:	000c02b7          	lui	x5,0xc0
//    800000bc:	0df2829b          	addiw	x5,x5,223
//    800000c0:	00c29293          	slli	x5,x5,0xc
//    800000c4:	ad028293          	addi	x5,x5,-1328 # bfad0 <_start-0x7ff40530>
//    800000c8:	000e0513          	addi	x10,x28,0
//    800000cc:	000105b7          	lui	x11,0x10
//    800000d0:	fff5859b          	addiw	x11,x11,-1
//    800000d4:	00b57533          	and	x10,x10,x11
//    800000d8:	00a2a023          	sw	x10,0(x5)
//    800000dc:	0ff0000f          	fence	iorw,iorw
//    800000e0:	00100e13          	addi	x28,x0,1
//    800000e4:	00000073          	ecall
//    800000e8:	80000297          	auipc	x5,0x80000
//    800000ec:	f1828293          	addi	x5,x5,-232 # 0 <_start-0x80000000>
//    800000f0:	00028e63          	beq	x5,x0,8000010c <reset_vector+0xc0>
//    800000f4:	10529073          	csrrw	x0,stvec,x5
//    800000f8:	0000b2b7          	lui	x5,0xb
//    800000fc:	1092829b          	addiw	x5,x5,265
//    80000100:	30229073          	csrrw	x0,medeleg,x5
//    80000104:	30202373          	csrrs	x6,medeleg,x0
//    80000108:	f2629ae3          	bne	x5,x6,8000003c <handle_exception>
//    8000010c:	30005073          	csrrwi	x0,mstatus,0
//    80000110:	00000297          	auipc	x5,0x0
//    80000114:	01428293          	addi	x5,x5,20 # 80000124 <reset_vector+0xd8>
//    80000118:	34129073          	csrrw	x0,mepc,x5
//    8000011c:	f1402573          	csrrs	x10,mhartid,x0
//    80000120:	30200073          	mret
//    80000124:	0ff0000f          	fence	iorw,iorw
//    80000128:	000c02b7          	lui	x5,0xc0
//    8000012c:	0df2829b          	addiw	x5,x5,223
//    80000130:	00c29293          	slli	x5,x5,0xc
//    80000134:	ad028293          	addi	x5,x5,-1328 # bfad0 <_start-0x7ff40530>
//    80000138:	000e0513          	addi	x10,x28,0
//    8000013c:	000105b7          	lui	x11,0x10
//    80000140:	fff5859b          	addiw	x11,x11,-1
//    80000144:	00b57533          	and	x10,x10,x11
//    80000148:	00a2a023          	sw	x10,0(x5)
//    8000014c:	0ff0000f          	fence	iorw,iorw
//    80000150:	00100e13          	addi	x28,x0,1
//    80000154:	00000073          	ecall
//    80000158:	c0001073          	unimp
//	...
//
//Disassembly of section .tohost:
//
//0000000080001000 <tohost>:
//	...
//
//0000000080001040 <fromhost>:
//	...
module bp_be_boot_rom #(parameter width_p=-1, addr_width_p=-1)
(input  [addr_width_p-1:0] addr_i
,output logic [width_p-1:0]      data_o
);
always_comb case(addr_i)
         0: data_o = width_p ' (512'b01010011100111100110111000010011000000000100000000000000011011110000000000001111010101000110001100110100001000000010111101110011000000000000111100000000011001110000000000001111000001000110001111111110000011110000111100010011100000000000000000001111000101110000001111111111000000100110001100000000101100000000111110010011000000111111111100000110011000110000000010010000000011111001001100000011111111110000101001100011000000001000000000001111100100110011010000100000001011110111001100000100110000000000000001101111); // 0x539E6E130040006F000F546334202F73000F0067000F0463FE0F0F1380000F1703FF026300B00F9303FF066300900F9303FF0A6300800F9334202F7304C0006F
         1: data_o = width_p ' (512'b00111010000000101001000001110011000000011111000000000010100100110011101100000010100100000111001111111111111100000000001010010011001100000101001010010000011100110000000111000010100000101001001100000000000000000000001010010111000110000000000001010000011100110011000001010010100100000111001100000001000000101000001010010011000000000000000000000010100101110000000000000101000100000110001111110001010000000010010101110011111111111001111111110000011011111111110111001111001000000010001100000000000000000001111100010111); // 0x3A02907301F002933B029073FFF002933052907301C28293000002971800507330529073010282930000029700051063F1402573FF9FF06FFDCF202300001F17
         2: data_o = width_p ' (512'b00001101111100101000001010011011000000000000110000000010101101110000111111110000000000000000111100000010000001010101110001100011000000011111010100010101000100110000000000010000000001010001001100110000010100101001000001110011111101101000001010000010100100110000000000000000000000101001011100000000000000000000111000010011001100000100000001010000011100110011000000110000010100000111001100110000001000000101000001110011001100000101001010010000011100110000000110000010100000101001001100000000000000000000001010010111); // 0x0DF2829B000C02B70FF0000F02055C6301F515130010051330529073F68282930000029700000E13304050733030507330205073305290730182829300000297
         3: data_o = width_p ' (512'b00010000100100101000001010011011000000000000000010110010101101110001000001010010100100000111001100000000000000101000111001100011111100011000001010000010100100111000000000000000000000101001011100000000000000000000000001110011000000000001000000001110000100110000111111110000000000000000111100000000101000101010000000100011000000001011010101110101001100111111111111110101100001011001101100000000000000010000010110110111000000000000111000000101000100111010110100000010100000101001001100000000110000101001001010010011); // 0x1092829B0000B2B71052907300028E63F1828293800002970000007300100E130FF0000F00A2A02300B57533FFF5859B000105B7000E0513AD02829300C29293
         4: data_o = width_p ' (512'b00000000000000010000010110110111000000000000111000000101000100111010110100000010100000101001001100000000110000101001001010010011000011011111001010000010100110110000000000001100000000101011011100001111111100000000000000001111001100000010000000000000011100111111000101000000001001010111001100110100000100101001000001110011000000010100001010000010100100110000000000000000000000101001011100110000000000000101000001110011111100100110001010011010111000110011000000100000001000110111001100110000001000101001000001110011); // 0x000105B7000E0513AD02829300C292930DF2829B000C02B70FF0000F30200073F140257334129073014282930000029730005073F2629AE33020237330229073
         5: data_o = width_p ' (512'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000001000001110011000000000000000000000000011100110000000000010000000011100001001100001111111100000000000000001111000000001010001010100000001000110000000010110101011101010011001111111111111101011000010110011011); // 0x000000000000000000000000000000000000000000000000000000000000000000000000C00010730000007300100E130FF0000F00A2A02300B57533FFF5859B
   default: data_o = { width_p { 1'b0 } };
endcase
endmodule
