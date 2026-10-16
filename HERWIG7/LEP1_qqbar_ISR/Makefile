PREFIX      = /home/badea/code/herwig715
HEPMC2_DIR  = $(PREFIX)
ROOTCFLAGS  = $(shell root-config --cflags)
ROOTLIBS    = $(shell root-config --libs)
ROOTLDFLAGS = $(shell root-config --ldflags)

CXX       = g++
CXXFLAGS  = -O2 -std=c++14 -Wall
INCLUDES  = -I$(HEPMC2_DIR)/include $(ROOTCFLAGS)
LDFLAGS   = -L$(HEPMC2_DIR)/lib -Wl,-rpath,$(HEPMC2_DIR)/lib
LIBS      = -lHepMC $(ROOTLIBS)

TARGET = hepmcToRoot

all: $(TARGET)

$(TARGET): hepmcToRoot.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ $< $(LDFLAGS) $(LIBS)

clean:
	rm -f $(TARGET)

.PHONY: all clean
