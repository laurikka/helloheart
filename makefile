all: intro.prg

intro.prg: intro.s
#		vasm6502_oldstyle -Fbin -cbm-prg -opt-branch intro.s -o intro.prg
		vasm6502_oldstyle -Fbin -cbm-prg intro.s -o intro.prg
#		exomizer sfx 2048 intro.prg -o introx.prg
		denise.exe intro.prg
#		retrodebugger.exe intro.prg
