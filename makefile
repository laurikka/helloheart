all: helloheart.prg

helloheart.prg: helloheart.s
		vasm6502_oldstyle -Fbin -illegal -cbm-prg helloheart.s -o helloheart.prg
		retrodebugger helloheart.prg
#		denise helloheart.prg

