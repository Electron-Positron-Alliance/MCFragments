# Links the KORALZ libraries built by ../build_gfortran.sh with the HepMC3 writer.
KZ   = ../korale-exp-final
FF   = -O -std=legacy -fno-automatic -finit-local-zero -w
HEPMC = /home/badea/code/local
LIBS = $(KZ)/korz_new/lib/glib.a $(KZ)/korz_new/diz4_9/glib.a $(KZ)/korz_new/yfs3-4-0/glib.a \
       $(KZ)/tauola/lib/glib.a $(KZ)/lib/glib.a $(KZ)/korz_new/nunulib/glib.a $(KZ)/korz_new/ttglib/glib.a

MainKoralzHepMC: MainKoralzHepMC.o hepmcWriter.o $(LIBS)
	gfortran -o $@ MainKoralzHepMC.o hepmcWriter.o $(LIBS) -Wl,-rpath,$(HEPMC)/lib64 -L$(HEPMC)/lib64 -lHepMC3 -lstdc++

MainKoralzHepMC.o: MainKoralzHepMC.f
	gfortran $(FF) -c $<

hepmcWriter.o: hepmcWriter.cc
	g++ -O2 -std=c++17 -I$(HEPMC)/include -c $<

$(KZ)/korz_new/diz4_9/glib.a: $(KZ)/korz_new/diz4_9/dzface.f
	cd $(KZ)/korz_new/diz4_9 && make F77=gfortran FFLAGS="$(FF)"

clean:
	rm -f *.o MainKoralzHepMC
