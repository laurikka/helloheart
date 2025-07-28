all: helloheart.prg

helloheart.prg: helloheart.s
		vasm6502_oldstyle -Fbin -cbm-prg helloheart.s -o helloheart.prg
		denise.exe helloheart.prg

