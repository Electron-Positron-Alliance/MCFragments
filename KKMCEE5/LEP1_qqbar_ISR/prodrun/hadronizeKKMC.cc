// hadronizeKKMC.cc
// ---------------------------------------------------------------------------
// Read KKMCee parton-level qqbar(+ISR) events from a HepMC3 Ascii file, feed
// the q/qbar (and carried ISR photons) into PYTHIA8, let PYTHIA8 do FSR +
// hadronization (Monash 2013 ee tune, default), and write a flat ROOT ntuple
// with the SAME branch layout as main304.cc / hepmcToRoot.cc.
//
// Output tree name: tgenBefore  (to match the gen-level pipeline).
//
// Design (per spec, modeled on PYTHIA8 main234.cc "supply-your-own-partons"):
//   ProcessLevel:all = off   (we provide the parton system ourselves)
//   PartonLevel:ISR  = off   (ISR already done by KKMCee)
//   PartonLevel:MPI  = off
//   PartonLevel:FSR  = on    (PYTHIA8 final-state QCD/QED shower)
//   HadronLevel:all  = on    (string fragmentation + decays)
//   Default Monash 2013 ee tune (Tune:ee = 7, applied by default; NOT overridden)
//
// Build (see bottom of file for exact command).
// ---------------------------------------------------------------------------

#include "Pythia8/Pythia.h"

#include "HepMC3/GenEvent.h"
#include "HepMC3/GenParticle.h"
#include "HepMC3/ReaderAscii.h"

#include "TFile.h"
#include "TTree.h"
#include "TMath.h"

#include <iostream>
#include <string>
#include <vector>
#include <cmath>

using namespace Pythia8;

#define MAXPARTICLE 5000

int main(int argc, char* argv[]) {

  std::string inFileName  = "events.hepmc3";
  std::string outFileName = "output.root";
  int nMax = -1; // -1 => all

  for (int i = 1; i < argc; ++i) {
    std::string a = argv[i];
    if      (a == "-f" && i+1 < argc) inFileName  = argv[++i];
    else if (a == "-o" && i+1 < argc) outFileName = argv[++i];
    else if (a == "-n" && i+1 < argc) nMax        = std::stoi(argv[++i]);
  }

  std::cout << "hadronizeKKMC: input  = " << inFileName  << std::endl;
  std::cout << "hadronizeKKMC: output = " << outFileName << std::endl;

  // ----------------------------------------------------------------------
  // PYTHIA8 setup: supply-your-own-partons + FSR + hadronization.
  // ----------------------------------------------------------------------
  Pythia pythia;
  Event& event      = pythia.event;

  pythia.readString("ProcessLevel:all = off"); // we provide the parton system
  pythia.readString("PartonLevel:ISR = off");  // ISR done by KKMCee
  pythia.readString("PartonLevel:MPI = off");  // no MPI in e+e-
  pythia.readString("PartonLevel:FSR = on");   // PYTHIA8 final-state shower
  pythia.readString("HadronLevel:all = on");   // fragmentation + decays
  // With ProcessLevel:all=off the PartonLevel FSR is NOT run automatically by
  // pythia.next(); it must be driven by hand with pythia.forceTimeShower(...)
  // BEFORE pythia.next() (see Pythia8 "Hadron-Level Standalone" doc). We do
  // that per event below. FSRinResonances is left off to avoid double showering.
  pythia.readString("PartonLevel:FSRinResonances = off");
  // Default Monash 2013 ee tune (Tune:ee = 7) is applied automatically; do
  // NOT override it so the FS hadronization matches the standalone Py8 sample.

  // Relax mother/daughter scrutiny: we build a non-standard parton record.
  pythia.readString("Check:event = off");

  // Quiet listing.
  pythia.readString("Next:numberShowInfo = 0");
  pythia.readString("Next:numberShowProcess = 0");
  pythia.readString("Next:numberShowEvent = 0");
  pythia.readString("Print:quiet = on");

  if (!pythia.init()) {
    std::cerr << "hadronizeKKMC: pythia.init() failed" << std::endl;
    return 1;
  }

  // ----------------------------------------------------------------------
  // HepMC3 input.
  // ----------------------------------------------------------------------
  HepMC3::ReaderAscii reader(inFileName);
  if (reader.failed()) {
    std::cerr << "hadronizeKKMC: cannot open " << inFileName << std::endl;
    return 1;
  }

  // ----------------------------------------------------------------------
  // ROOT output (branch layout identical to main304.cc / hepmcToRoot.cc).
  // ----------------------------------------------------------------------
  TFile* outFile = new TFile(outFileName.c_str(), "RECREATE");
  TTree* tree    = new TTree("tgenBefore", "KKMCee+Pythia8 hadronized event tree");

  float eCM;
  float sqrt_sHat;
  float mHat;
  float totalFinalM;
  Int_t nParticle;
  Bool_t ischarged[MAXPARTICLE];
  Bool_t isneutral[MAXPARTICLE];
  Bool_t passSphericity;
  float sphericity;
  float polarAngle;
  float thrust_val;
  float px[MAXPARTICLE];
  float py[MAXPARTICLE];
  float pz[MAXPARTICLE];
  float pt[MAXPARTICLE];
  float y_arr[MAXPARTICLE];
  float eta[MAXPARTICLE];
  float theta[MAXPARTICLE];
  float phi[MAXPARTICLE];
  float pmag[MAXPARTICLE];
  float mass[MAXPARTICLE];
  float energy[MAXPARTICLE];
  int pdgid[MAXPARTICLE];
  int status[MAXPARTICLE];
  int mother1[MAXPARTICLE];
  int mother2[MAXPARTICLE];
  int daughter1[MAXPARTICLE];
  int daughter2[MAXPARTICLE];
  int pwflag[MAXPARTICLE];
  float weight;

  tree->Branch("eCM",           &eCM,           "eCM/F");
  tree->Branch("sqrt_sHat",     &sqrt_sHat,     "sqrt_sHat/F");
  tree->Branch("mHat",          &mHat,          "mHat/F");
  tree->Branch("totalFinalM",   &totalFinalM,   "totalFinalM/F");
  tree->Branch("nParticle",     &nParticle,     "nParticle/I");
  tree->Branch("isCharged",     ischarged,      "isCharged[nParticle]/O");
  tree->Branch("isNeutral",     isneutral,      "isNeutral[nParticle]/O");
  tree->Branch("passSphericity",&passSphericity,"passSphericity/O");
  tree->Branch("px",            px,             "px[nParticle]/F");
  tree->Branch("py",            py,             "py[nParticle]/F");
  tree->Branch("pz",            pz,             "pz[nParticle]/F");
  tree->Branch("pt",            pt,             "pt[nParticle]/F");
  tree->Branch("pmag",          pmag,           "pmag[nParticle]/F");
  tree->Branch("mass",          mass,           "mass[nParticle]/F");
  tree->Branch("energy",        energy,         "energy[nParticle]/F");
  tree->Branch("y",             y_arr,          "y[nParticle]/F");
  tree->Branch("eta",           eta,            "eta[nParticle]/F");
  // NOTE: main304.cc intentionally points the theta branch at the eta array.
  // We use a correct theta array here (downstream reads branch names, not the
  // upstream bug); kept named "theta".
  tree->Branch("theta",         theta,          "theta[nParticle]/F");
  tree->Branch("weight",        &weight,        "weight/F");
  tree->Branch("phi",           phi,            "phi[nParticle]/F");
  tree->Branch("sphericity",    &sphericity,    "sphericity/F");
  tree->Branch("thrust",        &thrust_val,    "thrust/F");
  tree->Branch("polarAngle",    &polarAngle,    "polarAngle/F");
  tree->Branch("pdgid",         pdgid,          "pdgid[nParticle]/I");
  tree->Branch("status",        status,         "status[nParticle]/I");
  tree->Branch("mother1",       mother1,        "mother1[nParticle]/I");
  tree->Branch("mother2",       mother2,        "mother2[nParticle]/I");
  tree->Branch("daughter1",     daughter1,      "daughter1[nParticle]/I");
  tree->Branch("daughter2",     daughter2,      "daughter2[nParticle]/I");
  tree->Branch("pwflag",        pwflag,         "pwflag[nParticle]/I");

  // PYTHIA8 thrust/sphericity analysis objects (same as main304.cc).
  Thrust     thr;
  Sphericity sph;

  const Float_t sphLow  = 7.0f  * (Float_t)M_PI / 36.0f;
  const Float_t sphHigh = 29.0f * (Float_t)M_PI / 36.0f;

  long long nRead = 0, nGood = 0, nAbort = 0;

  while (true) {
    HepMC3::GenEvent ge(HepMC3::Units::GEV, HepMC3::Units::MM);
    if (!reader.read_event(ge)) break;
    if (reader.failed()) break;
    ++nRead;
    if (nMax >= 0 && nRead > nMax) { --nRead; break; }

    // Beam CM energy from the two beam particles (status 4).
    double eBeamSum = 0.0;
    int nBeam = 0;
    for (auto& p : ge.particles()) {
      if (p->status() == 4) { eBeamSum += std::fabs(p->momentum().e()); ++nBeam; }
    }

    // Collect the final-state colored partons (q, qbar, |id| in 1..5) and
    // final-state ISR photons (id==22). With KeyFSR=0 the only photons are
    // beam ISR; the only colored finals are q and qbar.
    std::vector<HepMC3::ConstGenParticlePtr> quarks;   // id > 0
    std::vector<HepMC3::ConstGenParticlePtr> antiquarks; // id < 0
    std::vector<HepMC3::ConstGenParticlePtr> photons;
    for (auto& p : ge.particles()) {
      if (p->status() != 1) continue;
      int id = p->pid();
      int aid = std::abs(id);
      if (aid >= 1 && aid <= 5) {
        if (id > 0) quarks.push_back(p);
        else        antiquarks.push_back(p);
      } else if (id == 22) {
        photons.push_back(p);
      }
    }

    // Require exactly one q and one qbar (a single color singlet pair).
    if (quarks.size() != 1 || antiquarks.size() != 1) {
      ++nAbort;
      continue;
    }

    HepMC3::ConstGenParticlePtr q  = quarks[0];
    HepMC3::ConstGenParticlePtr qb = antiquarks[0];

    // ------------------------------------------------------------------
    // Build the PYTHIA8 event record (Hadron-Level-Standalone pattern).
    //   index 0 : system (filled automatically by reset()).
    //   index 1 : q    (status 23, col=101, acol=0)
    //   index 2 : qbar (status 23, col=0,   acol=101)
    //   --> forceTimeShower(1, 2, scale) runs the FSR shower by hand
    //       (required: with ProcessLevel:all=off pythia.next() does NOT
    //        shower automatically).
    //   --> ISR photons appended afterward as status-1 finals.
    // Putting the qqbar at indices 1,2 (no beam lines) matches PYTHIA8
    // main234 "q qbar plus parton shower" (type 12) so forceTimeShower sees
    // a clean colour-singlet dipole.
    // ------------------------------------------------------------------
    event.reset();

    // Total parton-system 4-momentum (q + qbar) defines the FSR scale.
    Vec4 pQ ( q ->momentum().px(), q ->momentum().py(),
              q ->momentum().pz(), q ->momentum().e() );
    Vec4 pQb( qb->momentum().px(), qb->momentum().py(),
              qb->momentum().pz(), qb->momentum().e() );
    double mQpair = (pQ + pQb).mCalc();

    // Quark masses: use the KKMCee record masses (constituent masses) so the
    // four-momentum is internally consistent (E^2 - p^2 = m^2).
    double mq  = q ->momentum().m();
    double mqb = qb->momentum().m();
    if (mq  < 0) mq  = 0.0;
    if (mqb < 0) mqb = 0.0;

    // Append q and qbar as outgoing status-23 partons, colour singlet.
    int iQ  = event.append(q->pid(),  23, 101, 0,
                           pQ.px(),  pQ.py(),  pQ.pz(),  pQ.e(),  mq );
    int iQb = event.append(qb->pid(), 23, 0, 101,
                           pQb.px(), pQb.py(), pQb.pz(), pQb.e(), mqb);

    // Give the qqbar partons a starting shower scale (= pair invariant mass)
    // so PYTHIA8 FSR radiates down from the hard scale, then run the shower.
    double scale = mQpair;
    event[iQ ].scale(scale);
    event[iQb].scale(scale);
    pythia.forceTimeShower(iQ, iQb, scale);

    // Append the carried KKMCee ISR photons AFTER the shower so they are not
    // touched by it. They are carried through to the final record and are
    // included as pdgid==22 final particles (repo convention: photons kept).
    // We tag them with PYTHIA8 status code 43 (ISR/spacelike-shower photon) so
    // downstream code can treat KKMCee identically to PYTHIA8 (ISR photon =
    // status 43/44). status==43 is > 0, so the "isFinal = status>0" convention
    // keeps them in the final state and in the thrust computation. Note that
    // Pythia's internal Particle::isFinal() requires status==1, so we must NOT
    // rely on pa.isFinal() for these photons; we explicitly include status>0
    // particles below (see the final-particle loop).
    // LIMITATION: after forceTimeShower the original beam lines are not in the
    // record, so these photons carry no beam-ancestry mothers (mother=0).
    // Downstream ISR/photon handling keys off pdgid==22, not ancestry.
    for (auto& g : photons) {
      Vec4 pg(g->momentum().px(), g->momentum().py(),
              g->momentum().pz(), g->momentum().e());
      event.append(22, 43, 0, 0, 0, 0, 0, 0,
                   pg.px(), pg.py(), pg.pz(), pg.e(), 0.0);
    }

    // Hadronize (HadronLevel only; FSR already done above).
    if (!pythia.next()) {
      ++nAbort;
      continue;
    }
    ++nGood;

    // ------------------------------------------------------------------
    // Event-level observables (same definitions as main304.cc).
    // ------------------------------------------------------------------
    eCM = (eBeamSum > 1.0) ? (float)eBeamSum : 91.1876f;

    // Hard-scale masses: qqbar pair invariant mass (post-ISR system).
    mHat      = (float)mQpair;
    sqrt_sHat = (float)mQpair;

    sph.analyze(pythia.event);
    sphericity = (float)sph.sphericity();
    float polAngle = (float)TMath::ACos(
        std::max(-1.0, std::min(1.0, (double)sph.eventAxis(1).pz())));
    polarAngle = polAngle;
    passSphericity = (polAngle > sphLow && polAngle < sphHigh);

    thr.analyze(pythia.event);
    thrust_val = (float)thr.thrust();

    double totPx=0, totPy=0, totPz=0, totE=0;

    nParticle = 0;
    int n = pythia.event.size();
    if (n > MAXPARTICLE) n = MAXPARTICLE;
    for (int i = 0; i < n; ++i) {
      Particle& pa = pythia.event[i];

      if (pa.isFinal()) {
        totPx += pa.px(); totPy += pa.py(); totPz += pa.pz(); totE += pa.e();
      }

      ischarged[nParticle] = pa.isCharged();
      isneutral[nParticle] = !(pa.isCharged());
      px[nParticle]     = (float)pa.px();
      py[nParticle]     = (float)pa.py();
      pz[nParticle]     = (float)pa.pz();
      pmag[nParticle]   = (float)std::sqrt(pa.px()*pa.px()
                                + pa.py()*pa.py() + pa.pz()*pa.pz());
      pt[nParticle]     = (float)pa.pT();
      mass[nParticle]   = (float)pa.m();
      energy[nParticle] = (float)pa.e();
      eta[nParticle]    = (float)pa.eta();
      theta[nParticle]  = (float)pa.theta();
      phi[nParticle]    = (float)pa.phi();
      y_arr[nParticle]  = (float)pa.y();
      pdgid[nParticle]  = pa.id();
      status[nParticle] = pa.status();
      mother1[nParticle]   = pa.mother1();
      mother2[nParticle]   = pa.mother2();
      daughter1[nParticle] = pa.daughter1();
      daughter2[nParticle] = pa.daughter2();
      pwflag[nParticle]    = 0; // derived downstream from pdgid
      ++nParticle;
    }

    {
      double m2 = totE*totE - totPx*totPx - totPy*totPy - totPz*totPz;
      totalFinalM = (float)((m2 >= 0) ? std::sqrt(m2) : -std::sqrt(-m2));
    }
    weight = (float)pythia.info.weight();

    tree->Fill();
  }

  tree->Write();
  delete outFile;

  std::cout << "hadronizeKKMC: read " << nRead << " events, hadronized "
            << nGood << ", aborted/skipped " << nAbort << std::endl;
  return 0;
}
