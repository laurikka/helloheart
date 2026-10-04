all: helloheart.prg helloheart_sid.prg

helloheart.prg: helloheart.s
		vasm6502_oldstyle -Fbin -illegal -cbm-prg helloheart.s -o helloheart.prg
#		retrodebugger helloheart.prg
#		denise helloheart.prg
#		c1541 -format "helloheart,01" d64 helloheart.d64 -attach helloheart.d64 -write helloheart.prg helloheart

helloheart_sid.prg: helloheart_sid.s
		vasm6502_oldstyle -Fbin helloheart_sid.s -o helloheart.sid
#		vsid helloheart.sid

