data 'TMPL' (128, "nv! ") {
	$"1243 6865 636B 7375 6D20 2869 676E 6F72"            /* .Checksum (ignor */
	$"6564 2946 4C4E 4710 4C65 6E67 7468 2028"            /* ed)FLNG.Length ( */
	$"6967 6E6F 7265 6429 4657 5244 0E48 6967"            /* ignored)FWRD.Hig */
	$"6820 6861 6C66 2062 6974 7348 4259 5405"            /* h half bitsHBYT. */
	$"4269 7420 3742 4249 5405 4269 7420 3642"            /* Bit 7BBIT.Bit 6B */
	$"4249 5405 4269 7420 3542 4249 5405 4269"            /* BIT.Bit 5BBIT.Bi */
	$"7420 3442 4249 5405 4269 7420 3342 4249"            /* t 4BBIT.Bit 3BBI */
	$"5405 4269 7420 3242 4249 540E 6C69 7474"            /* T.Bit 2BBIT.litt */
	$"6C65 2D65 6E64 6961 6E3F 4242 4954 0A72"            /* le-endian?BBIT.r */
	$"6561 6C2D 6D6F 6465 3F42 4249 5409 7265"            /* eal-mode?BBIT�re */
	$"616C 2D62 6173 6548 4C4E 4709 7265 616C"            /* al-baseHLNG�real */
	$"2D73 697A 6548 4C4E 4709 7669 7274 2D62"            /* -sizeHLNG�virt-b */
	$"6173 6548 4C4E 4709 7669 7274 2D73 697A"            /* aseHLNG�virt-siz */
	$"6548 4C4E 47"                                       /* eHLNG */
};

data 'clut' (256, "iso*4") {
	$"0000 0000 0000 00FF 0000 0000 0000 0000"            /* .......�........ */
	$"0001 0000 0000 AAAA 0002 0000 AAAA 0000"            /* ......��....��.. */
	$"0003 0000 AAAA AAAA 0004 AAAA 0000 0000"            /* ....����..��.... */
	$"0005 AAAA 0000 AAAA 0006 AAAA AAAA 0000"            /* ..��..��..����.. */
	$"0007 AAAA AAAA AAAA 0008 5555 5555 5555"            /* ..������..UUUUUU */
	$"0009 5555 5555 FFFF 000A 5555 FFFF 5555"            /* .�UUUU��..UU��UU */
	$"000B 5555 FFFF FFFF 000C FFFF 5555 5555"            /* ..UU����..��UUUU */
	$"000D FFFF 5555 FFFF 000E FFFF FFFF 5555"            /* .���UU��..����UU */
	$"000F FFFF FFFF FFFF 0010 FFFF FFFF FFFF"            /* ..������..������ */
	$"0011 FFFF FFFF FFFF 0012 FFFF FFFF FFFF"            /* ..������..������ */
	$"0013 FFFF FFFF FFFF 0014 FFFF FFFF FFFF"            /* ..������..������ */
	$"0015 FFFF FFFF FFFF 0016 FFFF FFFF FFFF"            /* ..������..������ */
	$"0017 FFFF FFFF FFFF 0018 FFFF FFFF FFFF"            /* ..������..������ */
	$"0019 FFFF FFFF FFFF 001A FFFF FFFF FFFF"            /* ..������..������ */
	$"001B FFFF FFFF FFFF 001C FFFF FFFF FFFF"            /* ..������..������ */
	$"001D FFFF FFFF FFFF 001E FFFF FFFF FFFF"            /* ..������..������ */
	$"001F FFFF FFFF FFFF 0020 FFFF FFFF FFFF"            /* ..������. ������ */
	$"0021 FFFF FFFF FFFF 0022 FFFF FFFF FFFF"            /* .!������."������ */
	$"0023 FFFF FFFF FFFF 0024 FFFF FFFF FFFF"            /* .#������.$������ */
	$"0025 FFFF FFFF FFFF 0026 FFFF FFFF FFFF"            /* .%������.&������ */
	$"0027 FFFF FFFF FFFF 0028 FFFF FFFF FFFF"            /* .'������.(������ */
	$"0029 FFFF FFFF FFFF 002A FFFF FFFF FFFF"            /* .)������.*������ */
	$"002B FFFF FFFF FFFF 002C FFFF FFFF FFFF"            /* .+������.,������ */
	$"002D FFFF FFFF FFFF 002E FFFF FFFF FFFF"            /* .-������..������ */
	$"002F FFFF FFFF FFFF 0030 FFFF FFFF FFFF"            /* ./������.0������ */
	$"0031 FFFF FFFF FFFF 0032 FFFF FFFF FFFF"            /* .1������.2������ */
	$"0033 FFFF FFFF FFFF 0034 FFFF FFFF FFFF"            /* .3������.4������ */
	$"0035 FFFF FFFF FFFF 0036 FFFF FFFF FFFF"            /* .5������.6������ */
	$"0037 FFFF FFFF FFFF 0038 FFFF FFFF FFFF"            /* .7������.8������ */
	$"0039 FFFF FFFF FFFF 003A FFFF FFFF FFFF"            /* .9������.:������ */
	$"003B FFFF FFFF FFFF 003C FFFF FFFF FFFF"            /* .;������.<������ */
	$"003D FFFF FFFF FFFF 003E FFFF FFFF FFFF"            /* .=������.>������ */
	$"003F FFFF FFFF FFFF 0040 FFFF FFFF FFFF"            /* .?������.@������ */
	$"0041 FFFF FFFF FFFF 0042 FFFF FFFF FFFF"            /* .A������.B������ */
	$"0043 FFFF FFFF FFFF 0044 FFFF FFFF FFFF"            /* .C������.D������ */
	$"0045 FFFF FFFF FFFF 0046 FFFF FFFF FFFF"            /* .E������.F������ */
	$"0047 FFFF FFFF FFFF 0048 FFFF FFFF FFFF"            /* .G������.H������ */
	$"0049 FFFF FFFF FFFF 004A FFFF FFFF FFFF"            /* .I������.J������ */
	$"004B FFFF FFFF FFFF 004C FFFF FFFF FFFF"            /* .K������.L������ */
	$"004D FFFF FFFF FFFF 004E FFFF FFFF FFFF"            /* .M������.N������ */
	$"004F FFFF FFFF FFFF 0050 FFFF FFFF FFFF"            /* .O������.P������ */
	$"0051 FFFF FFFF FFFF 0052 FFFF FFFF FFFF"            /* .Q������.R������ */
	$"0053 FFFF FFFF FFFF 0054 FFFF FFFF FFFF"            /* .S������.T������ */
	$"0055 FFFF FFFF FFFF 0056 FFFF FFFF FFFF"            /* .U������.V������ */
	$"0057 FFFF FFFF FFFF 0058 FFFF FFFF FFFF"            /* .W������.X������ */
	$"0059 FFFF FFFF FFFF 005A FFFF FFFF FFFF"            /* .Y������.Z������ */
	$"005B FFFF FFFF FFFF 005C FFFF FFFF FFFF"            /* .[������.\������ */
	$"005D FFFF FFFF FFFF 005E FFFF FFFF FFFF"            /* .]������.^������ */
	$"005F FFFF FFFF FFFF 0060 FFFF FFFF FFFF"            /* ._������.`������ */
	$"0061 FFFF FFFF FFFF 0062 FFFF FFFF FFFF"            /* .a������.b������ */
	$"0063 FFFF FFFF FFFF 0064 FFFF FFFF FFFF"            /* .c������.d������ */
	$"0065 FFFF FFFF FFFF 0066 FFFF FFFF FFFF"            /* .e������.f������ */
	$"0067 FFFF FFFF FFFF 0068 FFFF FFFF FFFF"            /* .g������.h������ */
	$"0069 FFFF FFFF FFFF 006A FFFF FFFF FFFF"            /* .i������.j������ */
	$"006B FFFF FFFF FFFF 006C FFFF FFFF FFFF"            /* .k������.l������ */
	$"006D FFFF FFFF FFFF 006E FFFF FFFF FFFF"            /* .m������.n������ */
	$"006F FFFF FFFF FFFF 0070 FFFF FFFF FFFF"            /* .o������.p������ */
	$"0071 FFFF FFFF FFFF 0072 FFFF FFFF FFFF"            /* .q������.r������ */
	$"0073 FFFF FFFF FFFF 0074 FFFF FFFF FFFF"            /* .s������.t������ */
	$"0075 FFFF FFFF FFFF 0076 FFFF FFFF FFFF"            /* .u������.v������ */
	$"0077 FFFF FFFF FFFF 0078 FFFF FFFF FFFF"            /* .w������.x������ */
	$"0079 FFFF FFFF FFFF 007A FFFF FFFF FFFF"            /* .y������.z������ */
	$"007B FFFF FFFF FFFF 007C FFFF FFFF FFFF"            /* .{������.|������ */
	$"007D FFFF FFFF FFFF 007E FFFF FFFF FFFF"            /* .}������.~������ */
	$"007F FFFF FFFF FFFF 0080 FFFF FFFF FFFF"            /* ..������.������� */
	$"0081 FFFF FFFF FFFF 0082 FFFF FFFF FFFF"            /* .�������.������� */
	$"0083 FFFF FFFF FFFF 0084 FFFF FFFF FFFF"            /* .�������.������� */
	$"0085 FFFF FFFF FFFF 0086 FFFF FFFF FFFF"            /* .�������.������� */
	$"0087 FFFF FFFF FFFF 0088 FFFF FFFF FFFF"            /* .�������.������� */
	$"0089 FFFF FFFF FFFF 008A FFFF FFFF FFFF"            /* .�������.������� */
	$"008B FFFF FFFF FFFF 008C FFFF FFFF FFFF"            /* .�������.������� */
	$"008D FFFF FFFF FFFF 008E FFFF FFFF FFFF"            /* .�������.������� */
	$"008F FFFF FFFF FFFF 0090 FFFF FFFF FFFF"            /* .�������.������� */
	$"0091 FFFF FFFF FFFF 0092 FFFF FFFF FFFF"            /* .�������.������� */
	$"0093 FFFF FFFF FFFF 0094 FFFF FFFF FFFF"            /* .�������.������� */
	$"0095 FFFF FFFF FFFF 0096 FFFF FFFF FFFF"            /* .�������.������� */
	$"0097 FFFF FFFF FFFF 0098 FFFF FFFF FFFF"            /* .�������.������� */
	$"0099 FFFF FFFF FFFF 009A FFFF FFFF FFFF"            /* .�������.������� */
	$"009B FFFF FFFF FFFF 009C FFFF FFFF FFFF"            /* .�������.������� */
	$"009D FFFF FFFF FFFF 009E FFFF FFFF FFFF"            /* .�������.������� */
	$"009F FFFF FFFF FFFF 00A0 FFFF FFFF FFFF"            /* .�������.������� */
	$"00A1 FFFF FFFF FFFF 00A2 FFFF FFFF FFFF"            /* .�������.������� */
	$"00A3 FFFF FFFF FFFF 00A4 FFFF FFFF FFFF"            /* .�������.������� */
	$"00A5 FFFF FFFF FFFF 00A6 FFFF FFFF FFFF"            /* .�������.������� */
	$"00A7 FFFF FFFF FFFF 00A8 FFFF FFFF FFFF"            /* .�������.������� */
	$"00A9 FFFF FFFF FFFF 00AA FFFF FFFF FFFF"            /* .�������.������� */
	$"00AB FFFF FFFF FFFF 00AC FFFF FFFF FFFF"            /* .�������.������� */
	$"00AD FFFF FFFF FFFF 00AE FFFF FFFF FFFF"            /* .�������.������� */
	$"00AF FFFF FFFF FFFF 00B0 FFFF FFFF FFFF"            /* .�������.������� */
	$"00B1 FFFF FFFF FFFF 00B2 FFFF FFFF FFFF"            /* .�������.������� */
	$"00B3 FFFF FFFF FFFF 00B4 FFFF FFFF FFFF"            /* .�������.������� */
	$"00B5 FFFF FFFF FFFF 00B6 FFFF FFFF FFFF"            /* .�������.������� */
	$"00B7 FFFF FFFF FFFF 00B8 FFFF FFFF FFFF"            /* .�������.������� */
	$"00B9 FFFF FFFF FFFF 00BA FFFF FFFF FFFF"            /* .�������.������� */
	$"00BB FFFF FFFF FFFF 00BC FFFF FFFF FFFF"            /* .�������.������� */
	$"00BD FFFF FFFF FFFF 00BE FFFF FFFF FFFF"            /* .�������.������� */
	$"00BF FFFF FFFF FFFF 00C0 FFFF FFFF FFFF"            /* .�������.������� */
	$"00C1 FFFF FFFF FFFF 00C2 FFFF FFFF FFFF"            /* .�������.������� */
	$"00C3 FFFF FFFF FFFF 00C4 FFFF FFFF FFFF"            /* .�������.������� */
	$"00C5 FFFF FFFF FFFF 00C6 FFFF FFFF FFFF"            /* .�������.������� */
	$"00C7 FFFF FFFF FFFF 00C8 FFFF FFFF FFFF"            /* .�������.������� */
	$"00C9 FFFF FFFF FFFF 00CA FFFF FFFF FFFF"            /* .�������.������� */
	$"00CB FFFF FFFF FFFF 00CC FFFF FFFF FFFF"            /* .�������.������� */
	$"00CD FFFF FFFF FFFF 00CE FFFF FFFF FFFF"            /* .�������.������� */
	$"00CF FFFF FFFF FFFF 00D0 FFFF FFFF FFFF"            /* .�������.������� */
	$"00D1 FFFF FFFF FFFF 00D2 FFFF FFFF FFFF"            /* .�������.������� */
	$"00D3 FFFF FFFF FFFF 00D4 FFFF FFFF FFFF"            /* .�������.������� */
	$"00D5 FFFF FFFF FFFF 00D6 FFFF FFFF FFFF"            /* .�������.������� */
	$"00D7 FFFF FFFF FFFF 00D8 FFFF FFFF FFFF"            /* .�������.������� */
	$"00D9 FFFF FFFF FFFF 00DA FFFF FFFF FFFF"            /* .�������.������� */
	$"00DB FFFF FFFF FFFF 00DC FFFF FFFF FFFF"            /* .�������.������� */
	$"00DD FFFF FFFF FFFF 00DE FFFF FFFF FFFF"            /* .�������.������� */
	$"00DF FFFF FFFF FFFF 00E0 FFFF FFFF FFFF"            /* .�������.������� */
	$"00E1 FFFF FFFF FFFF 00E2 FFFF FFFF FFFF"            /* .�������.������� */
	$"00E3 FFFF FFFF FFFF 00E4 FFFF FFFF FFFF"            /* .�������.������� */
	$"00E5 FFFF FFFF FFFF 00E6 FFFF FFFF FFFF"            /* .�������.������� */
	$"00E7 FFFF FFFF FFFF 00E8 FFFF FFFF FFFF"            /* .�������.������� */
	$"00E9 FFFF FFFF FFFF 00EA FFFF FFFF FFFF"            /* .�������.������� */
	$"00EB FFFF FFFF FFFF 00EC FFFF FFFF FFFF"            /* .�������.������� */
	$"00ED FFFF FFFF FFFF 00EE FFFF FFFF FFFF"            /* .�������.������� */
	$"00EF FFFF FFFF FFFF 00F0 FFFF FFFF FFFF"            /* .�������.������� */
	$"00F1 FFFF FFFF FFFF 00F2 FFFF FFFF FFFF"            /* .�������.������� */
	$"00F3 FFFF FFFF FFFF 00F4 FFFF FFFF FFFF"            /* .�������.������� */
	$"00F5 FFFF FFFF FFFF 00F6 FFFF FFFF FFFF"            /* .�������.������� */
	$"00F7 FFFF FFFF FFFF 00F8 FFFF FFFF FFFF"            /* .�������.������� */
	$"00F9 FFFF FFFF FFFF 00FA FFFF FFFF FFFF"            /* .�������.������� */
	$"00FB FFFF FFFF FFFF 00FC FFFF FFFF FFFF"            /* .�������.������� */
	$"00FD FFFF FFFF FFFF 00FE FFFF FFFF FFFF"            /* .�������.������� */
	$"00FF FFFF FFFF FFFF"                                /* .������� */
};

data 'nv! ' (1001, "Default") {
	$"0000 0000 0080 0008 FFFF FFFF FFFF FFFF"            /* .....�......���� */
	$"C000 0000 FFFF FFFF 0080 0000 0000 0300"            /* �...����.�...... */
	$"0000 0300 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 6B65 7962 6F61 7264"            /* ........keyboard */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 7363 7265 656E 0000"            /* ........screen.. */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0000"            /* ................ */
};

data 'zcod' (1111, "Visor68K", purgeable) {
	$"2E0F 7008 A08D 2E47 007C 0700 4E71 207C"            /* ..p.��.G.|..Nq | */
	$"4761 7279 227C 0505 1956 203C 0000 C000"            /* Gary"|...V <..�. */
	$"7400 4E70 588F FE03 67FC 4E74 0004"                 /* t.NpX��.g�Nt.. */
};

data 'SIZE' (1) {
	$"0000 001F 4000 0006 0000"                           /* ....@..... */
};

data 'SIZE' (0) {
	$"0000 001F 4000 0006 0000"                           /* ....@..... */
};

data 'cfrg' (0) {
	$"0000 0000 0000 0000 0000 0001 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0000 0000 0000 0001"            /* ................ */
	$"7077 7063 0000 0000 0000 0000 0000 0000"            /* pwpc............ */
	$"0000 0000 0000 0101 0000 0000 0000 0000"            /* ................ */
	$"0000 0000 0000 0000 0038 0D6D 6163 2D73"            /* .........8�mac-s */
	$"6563 6F6E 6461 7279"                                /* econdary */
};

