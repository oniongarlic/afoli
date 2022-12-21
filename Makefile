all: afoli

afoli: afoli.gpr afoli.adb
	gprbuild -Pafoli.gpr

clean:
	rm -f *.o afoli
