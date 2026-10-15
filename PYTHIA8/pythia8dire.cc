
// Copyright (C) 2025 Torbjorn Sjostrand.
// PYTHIA is licenced under the GNU GPL v2 or later, see COPYING for details.
// Please respect the MCnet Guidelines, see GUIDELINES for details.

// Authors: Rene Brun, Axel Naumann and Bernhard Meirose

// Keywords: analysis; root

// This is a simple test program, based on main101.cc,
// but modified to use ROOT for histogramming.
// It studies the charged multiplicity distribution at the LHC.

// WARNING: for currently unknown reasons it may hang
// with an empty canvas on a Mac.

// Header file to access Pythia 8 program elements.
#include "Pythia8/Pythia.h"

// ROOT, for histogramming.
#include "TH1.h"

// ROOT, TTree for writing output
#include "TTree.h"
#include "TMath.h"
#include "TLorentzVector.h"

// ROOT, for interactive graphics.
#include "TVirtualPad.h"
#include "TApplication.h"

// ROOT, for saving file.
#include "TFile.h"
#define MAXPARTICLE 1000

// c++ code
#include <sstream>

using namespace Pythia8;

//==========================================================================

int main(int argc, char* argv[]) {

  // user arguments
  std::string outFileName ="PYTHIA8_LEP1_DireShower.root";
  int nEvent = 1e4;
  for (int i = 1; i < argc; i++) {
    if (strncmp(argv[i], "-o", 2) == 0) outFileName = argv[i + 1];
    if (strncmp(argv[i], "-n", 2) == 0) nEvent = std::stoi(argv[i + 1]);
  }
  
  // Create the ROOT application environment.
  TApplication theApp("hist", &argc, argv);

  // Create Pythia instance and set it up to generate hard QCD processes
  // above pTHat = 20 GeV for pp collisions at 14 TeV.
  Pythia pythia;
  // int nEvent = 5e6;
  // Allow no substructure in e+- beams: normal for corrected LEP data.
  pythia.readString("PDF:lepton = off");
  // Process selection.
  pythia.readString("WeakSingleBoson:ffbar2gmZ = on");
  // Switch off all Z0 decays and then switch back on those to quarks.
  pythia.readString("23:onMode = off");
  pythia.readString("23:onIfAny = 1 2 3 4 5");
  // try to limit QED conversions
  //Number of allowed lepton flavours in gamma → l+ l- branchings (phase space permitting). A change to 2 would exclude gamma → tau+ tau-, and a change to 1 also gamma → mu+ mu-.
  //pythia.readString("TimeShower:nGammaToLepton = 0"); 

  
  // vincia = 2 // dire = 3
  pythia.readString("PartonShowers:Model = 3");


  // LEP1 initialization at Z0 mass.
  pythia.readString("Beams:idA =  11");
  pythia.readString("Beams:idB = -11");
  double mZ = pythia.particleData.m0(23);
  pythia.settings.parm("Beams:eCM", mZ);

  // SWITCH TO TURN ON/OFF Hadronization
  // pythia.readString("HadronLevel:Hadronize=  off");

  // set alpha_strong value at scale M_Z^2.
  //pythia.readString("SigmaProcess:alphaSvalue= 0.1136"); // value from https://arxiv.org/abs/2412.15164
  //pythia.readString("SigmaProcess:alphaSvalue= 0.1180"); // value from world average https://pdg.lbl.gov/2024/reviews/rpp2024-rev-qcd.pdf

  // If Pythia fails to initialize, exit with error.
  if (!pythia.init()) return 1;

  // Create file on which histogram(s) can be saved.
  TFile* outFile = new TFile(outFileName.c_str(), "RECREATE");
  TTree*    tree = new TTree("tgenBefore","Pythia8 event tree");

  float eCM;
  float sqrt_sHat;
  float totalFinalM;
  Int_t nParticle;
  Bool_t ischarged[MAXPARTICLE];
  Bool_t isneutral[MAXPARTICLE];
  Bool_t passSphericity;
  float sphericity;
  float polarAngle;
  float thrust;
  float px[MAXPARTICLE];
  float py[MAXPARTICLE];
  float pz[MAXPARTICLE];
  float pt[MAXPARTICLE];
  float y[MAXPARTICLE];
  float eta[MAXPARTICLE];
  float theta[MAXPARTICLE];
  float phi[MAXPARTICLE];
  float pmag[MAXPARTICLE];
  float mass[MAXPARTICLE];
  int pdgid[MAXPARTICLE];
  int status[MAXPARTICLE];
  int mother1[MAXPARTICLE];
  int mother2[MAXPARTICLE];
  int daughter1[MAXPARTICLE];
  int daughter2[MAXPARTICLE];
  float weight;
  
  tree->Branch("eCM",&eCM,"eCM/F");
  tree->Branch("sqrt_sHat",&sqrt_sHat,"sqrt_sHat/F");
  tree->Branch("totalFinalM",&totalFinalM,"totalFinalM/F");
  tree->Branch("nParticle",&nParticle,"nParticle/I");
  tree->Branch("isCharged", ischarged, "isCharged[nParticle]/O"); // 'O' = bool
  tree->Branch("isNeutral", isneutral, "isNeutral[nParticle]/O"); // 'O' = bool
  tree->Branch("passSphericity", passSphericity, "passSphericity/O"); // 'O' = bool
  tree->Branch("px",px,"px[nParticle]/F");
  tree->Branch("py",py,"py[nParticle]/F");
  tree->Branch("pz",pz,"pz[nParticle]/F");
  tree->Branch("pt",pt,"pt[nParticle]/F");
  tree->Branch("pmag",pmag,"pmag[nParticle]/F");
  tree->Branch("mass",mass,"mass[nParticle]/F");
  tree->Branch("y",y,"y[nParticle]/F");
  tree->Branch("eta",eta,"eta[nParticle]/F");
  tree->Branch("theta",eta,"theta[nParticle]/F");
  tree->Branch("weight",&weight,"weight/F");
  tree->Branch("phi",phi,"phi[nParticle]/F");
  tree->Branch("sphericity",&sphericity,"sphericity/F");
  tree->Branch("thrust",&thrust,"thrust/F");
  tree->Branch("polarAngle",&polarAngle,"polarAngle/F");
  tree->Branch("pdgid", &pdgid, "pdgid[nParticle]/I"); 
  tree->Branch("status", &pdgid, "status[nParticle]/I");
  tree->Branch("mother1", &pdgid, "mother1[nParticle]/I");
  tree->Branch("mother2", &pdgid, "mother2[nParticle]/I");
  tree->Branch("daughter1", &pdgid, "daughter1[nParticle]/I");
  tree->Branch("daughter2", &pdgid, "daughter2[nParticle]/I");
  
  // Begin event loop. Generate event; skip if generation aborted.
  for (int iEvent = 0; iEvent < nEvent; ++iEvent) {
    if (!pythia.next()) continue;
    
    if (iEvent % 100000 == 0) std::cout << "On event " << iEvent << std::endl;

    // scales
    eCM = pythia.info.eCM();
    sqrt_sHat = TMath::Sqrt(pythia.info.sHat());
    
    // Find number of all final charged particles.
    nParticle = 0; 
    int index = 0; 
    weight = pythia.info.weight(); 

    // sphericity
    Sphericity sph; 
    sph.analyze(pythia.event);
    sphericity = sph.sphericity();
    Float_t sphericityThresholdLow = 7*TMath::Pi()/36;
    Float_t sphericityThresholdHigh = 29*TMath::Pi()/36;
    // calculate the polar angle of the event axis
    Float_t polAngle = TMath::ACos(sph.eventAxis(1).pz());
    polarAngle = polAngle;
    passSphericity = (polAngle> sphericityThresholdLow && polAngle < sphericityThresholdHigh);

    // thrust
    Thrust thr;
    thr.analyze(pythia.event);
    thrust = thr.thrust();

    // total vector
    TLorentzVector total;
    
    for (int i = 0; i < pythia.event.size(); ++i){
      // only fill info for final state particles
      if(pythia.event[i].isFinal()){

	// add to total
	//total += pythia.event[i].p();
	
        ischarged[index] = pythia.event[i].isCharged(); 
        isneutral[index] = !(pythia.event[i].isCharged());
        
        px[index]     = pythia.event[i].px(); 
        py[index]     = pythia.event[i].py(); 
        pz[index]     = pythia.event[i].pz();
        pmag[index]   = TMath::Sqrt(pythia.event[i].px()*pythia.event[i].px() + pythia.event[i].py()*pythia.event[i].py() + pythia.event[i].pz()*pythia.event[i].pz());
        pt[index]     = pythia.event[i].pT(); 
        mass[index]   = pythia.event[i].m(); 
        eta[index]    = pythia.event[i].eta();
	theta[index]  = pythia.event[i].theta();
        phi[index]    = pythia.event[i].phi(); 
        y[index]      = pythia.event[i].y();
	pdgid[index]  = pythia.event[i].id();
	status[index] = pythia.event[i].status();
        mother1[index] = pythia.event[i].mother1();
	mother2[index] = pythia.event[i].mother2();
	std::cout << "Mother1 : " << pythia.event[i].mother1() << " mother 2: " << pythia.event[i].mother2() << std::endl; 
	daughter1[index] = pythia.event[i].daughter1();
	daughter2[index] = pythia.event[i].daughter2();
	
	
        nParticle++; 
        index++; 
      }
    }

    totalFinalM = total.M();
    
    tree->Fill(); 
      
  } // end event loop
  

  // Statistics on event generation.
  //pythia.stat();

  tree->Write(); 
  delete outFile;

  // Done.
  return 0;
}
