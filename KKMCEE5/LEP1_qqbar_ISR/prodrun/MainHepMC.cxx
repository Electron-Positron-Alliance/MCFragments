// MainHepMC.cxx -- smoke-test driver for C++ KKMCee.
// Based on MainMini.cxx, but writes the in-memory HepMC3 GenEvent (m_Hvent),
// which KKee2f fills each Generate() call via m_HEPMC->WriteHEPC(),
// out to a HepMC3 Ascii file using the supported HepMC3::WriterAscii.
// Number of events and output filename are taken from argv to keep it scriptable.
#include "TRandom3.h"
#include "TH1.h"
#include "KKee2f.h"
#include "HepMC3/GenEvent.h"
#include "HepMC3/WriterAscii.h"
#include <cstdlib>
/////////////////////////////////////////////////////////////
int main(int argc, char** argv){
int NevGen = 2000;
std::string outName = "events.hepmc3";
if( argc > 1 ) NevGen  = atoi(argv[1]);
if( argc > 2 ) outName = argv[2];

// Random-number seed for the central TRandom3 that drives KKMCee (ISR/FSR/FOAM/
// GPS all pull from this single generator via f_RNgen). To make production
// shards statistically independent, the seed is configurable:
//   1) argv[3]                 (highest priority)
//   2) environment KKMC_SEED   (fallback, convenient for batch scripts)
//   3) default 54217137        (original hardcoded value)
long iniseed = 54217137;
if( argc > 3 ) {
   iniseed = atol(argv[3]);
} else {
   const char* envSeed = getenv("KKMC_SEED");
   if( envSeed != NULL && envSeed[0] != '\0' ) iniseed = atol(envSeed);
}
cout<<"MainHepMC: using random seed iniseed = "<< iniseed <<endl;

ofstream   OutFile("pro.output",ios::out);  // Logfile output
TFile *MCgenFile = new TFile("mcgen.root","RECREATE","Generators");
MCgenFile->cd();
TRandom3 *RN_gen = new TRandom3();// Central random numb. gen.
RN_gen->SetSeed(iniseed);
/////////////////////////////////////////////////////////////
KKee2f *KKMCgen = new KKee2f("MCgen"); // MC generator object
/////////////////////////////////////////////////////////////
int nb = 10000;
TH1D *h_NORMA= new TH1D("KKMCgen_NORMA","Normaliz. histo",nb,0,nb);
KKMCgen->Initialize( RN_gen, &OutFile, h_NORMA);
/////////////////////////////////////////////////////////////
HepMC3::WriterAscii hepmc_writer(outName);
cout<<"MainHepMC: generating "<< NevGen <<" events, writing HepMC3 to "<< outName <<endl;
long nWritten = 0;
/////////////////////////////////////////////////////////////
// Loop over MC events
for(int iev=1; iev<=NevGen; iev++) {
   KKMCgen->Generate();
   HepMC3::GenEvent *Hvent = (HepMC3::GenEvent*) KKMCgen->m_Hvent;
   if( Hvent != NULL ){
      Hvent->set_event_number(iev);
      hepmc_writer.write_event(*Hvent);
      nWritten++;
   }
   if( (iev/1000)*1000 == iev || iev<=3) {
       cout<<"MainHepMC: iev="<<iev<<endl;
   }//if
}// for iev
hepmc_writer.close();
cout<<"MainHepMC: wrote "<< nWritten <<" events to "<< outName <<endl;
/////////////////////////////////////////////////////////////
KKMCgen->Finalize(); // final printout
KKMCgen->Write("MCgen",TObject::kOverwrite);
RN_gen->Write("RN_gen",TObject::kOverwrite);
MCgenFile->Write();
MCgenFile->Close();
return 0;
}// main
