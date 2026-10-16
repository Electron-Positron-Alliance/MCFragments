// hepmcToRoot.cc
// Reads HepMC2 output from Herwig 7.1.5 and fills a ROOT TTree
// with the same structure as Pythia8 main304.cc
//
// Usage: ./hepmcToRoot -o output.root -f input.hepmc

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <cmath>
#include <algorithm>

// HepMC2
#include "HepMC/IO_GenEvent.h"
#include "HepMC/GenEvent.h"
#include "HepMC/GenParticle.h"
#include "HepMC/GenVertex.h"

// ROOT
#include "TFile.h"
#include "TTree.h"
#include "TMath.h"
#include "TVector3.h"

#define MAXPARTICLE 5000

// Simple 4-vector struct (avoid TLorentzVector which needs GenVector headers)
struct FourVec {
    double px, py, pz, e;
    FourVec() : px(0), py(0), pz(0), e(0) {}
    FourVec(double x, double y, double z, double en) : px(x), py(y), pz(z), e(en) {}
    FourVec& operator+=(const FourVec& o) {
        px += o.px; py += o.py; pz += o.pz; e += o.e;
        return *this;
    }
    double M() const {
        double m2 = e*e - px*px - py*py - pz*pz;
        return (m2 >= 0) ? std::sqrt(m2) : -std::sqrt(-m2);
    }
};

// ---- Thrust calculation (N(N-1)/2 pair axis iteration as in Herwig++) ----
double calcThrust(const std::vector<TVector3>& momenta) {
    int n = momenta.size();
    if (n < 2) return 1.0;

    double pTotal = 0.0;
    for (int k = 0; k < n; ++k) pTotal += momenta[k].Mag();
    if (pTotal < 1e-10) return 1.0;

    double maxThrust = 0.0;

    // Lambda to compute thrust along a given axis
    auto thrustAlongAxis = [&](const TVector3& axis) -> double {
        double sum = 0.0;
        for (int k = 0; k < n; ++k)
            sum += std::fabs(momenta[k].Dot(axis));
        return sum / pTotal;
    };

    // Try all N(N-1)/2 pairs as candidate axis directions
    for (int i = 0; i < n; ++i) {
        for (int j = i+1; j < n; ++j) {
            TVector3 axis = momenta[i] + momenta[j];
            if (axis.Mag() < 1e-10) continue;
            axis = axis.Unit();
            double t = thrustAlongAxis(axis);
            if (t > maxThrust) maxThrust = t;
            TVector3 negAxis = -axis;
            t = thrustAlongAxis(negAxis);
            if (t > maxThrust) maxThrust = t;
        }
    }

    // Also try each momentum direction as axis
    for (int i = 0; i < n; ++i) {
        if (momenta[i].Mag() < 1e-10) continue;
        TVector3 axis = momenta[i].Unit();
        double t = thrustAlongAxis(axis);
        if (t > maxThrust) maxThrust = t;
        TVector3 negAxis = -axis;
        t = thrustAlongAxis(negAxis);
        if (t > maxThrust) maxThrust = t;
    }

    return maxThrust;
}

// ---- Sphericity tensor and event axis ----
struct SphericityResult {
    double sphericity;
    TVector3 axis1; // principal axis
};

SphericityResult calcSphericity(const std::vector<TVector3>& momenta) {
    SphericityResult res;
    res.sphericity = 0.0;
    res.axis1 = TVector3(0,0,1);

    // Build momentum tensor S_ij = sum(p_i * p_j) / sum(|p|^2)
    double Sxx=0, Sxy=0, Sxz=0, Syy=0, Syz=0, Szz=0;
    double norm = 0.0;
    for (const auto& p : momenta) {
        double p2 = p.Mag2();
        norm += p2;
        Sxx += p.X()*p.X();
        Sxy += p.X()*p.Y();
        Sxz += p.X()*p.Z();
        Syy += p.Y()*p.Y();
        Syz += p.Y()*p.Z();
        Szz += p.Z()*p.Z();
    }
    if (norm < 1e-20) return res;

    Sxx /= norm; Sxy /= norm; Sxz /= norm;
    Syy /= norm; Syz /= norm; Szz /= norm;

    double trace = Sxx + Syy + Szz;
    double b = Sxx*Syy + Sxx*Szz + Syy*Szz - Sxy*Sxy - Sxz*Sxz - Syz*Syz;
    double det = Sxx*(Syy*Szz - Syz*Syz) - Sxy*(Sxy*Szz - Syz*Sxz) + Sxz*(Sxy*Syz - Syy*Sxz);

    double p_c = b - trace*trace/3.0;
    double q_c = 2.0*trace*trace*trace/27.0 - trace*b/3.0 + det;
    double disc = q_c*q_c/4.0 + p_c*p_c*p_c/27.0;

    double lambda[3];
    if (disc > 0) {
        double A = std::cbrt(-q_c/2.0 + std::sqrt(disc));
        double B_v = std::cbrt(-q_c/2.0 - std::sqrt(disc));
        lambda[0] = A + B_v + trace/3.0;
        lambda[1] = lambda[0];
        lambda[2] = lambda[0];
    } else {
        double r = std::sqrt(-p_c*p_c*p_c/27.0);
        double costheta = (r > 1e-20) ? (-q_c/(2.0*r)) : 0.0;
        costheta = std::max(-1.0, std::min(1.0, costheta));
        double theta = std::acos(costheta)/3.0;
        double cr = std::cbrt(r);
        lambda[0] = 2.0*cr*std::cos(theta) + trace/3.0;
        lambda[1] = 2.0*cr*std::cos(theta + 2.0*M_PI/3.0) + trace/3.0;
        lambda[2] = 2.0*cr*std::cos(theta + 4.0*M_PI/3.0) + trace/3.0;
    }

    // Sort: lambda[0] >= lambda[1] >= lambda[2]
    std::sort(lambda, lambda+3, std::greater<double>());

    res.sphericity = 1.5 * (lambda[1] + lambda[2]);
    if (res.sphericity < 0) res.sphericity = 0;
    if (res.sphericity > 1) res.sphericity = 1;

    // Find eigenvector for lambda[0] via null-space of (S - lambda[0]*I)
    double A00 = Sxx - lambda[0], A01 = Sxy, A02 = Sxz;
    double A10 = Sxy, A11 = Syy - lambda[0], A12 = Syz;
    double A20 = Sxz, A21 = Syz, A22 = Szz - lambda[0];

    TVector3 v1(A00, A01, A02);
    TVector3 v2(A10, A11, A12);
    TVector3 v3(A20, A21, A22);
    TVector3 axis = v1.Cross(v2);
    if (axis.Mag() < 1e-10) axis = v1.Cross(v3);
    if (axis.Mag() < 1e-10) axis = v2.Cross(v3);
    if (axis.Mag() > 1e-10) res.axis1 = axis.Unit();

    return res;
}

// Determine if a particle is charged (simplified PDG-based)
bool isChargedParticle(int pdgId) {
    int pid = std::abs(pdgId);
    // Neutral particles
    if (pid == 22) return false;   // photon
    if (pid == 12 || pid == 14 || pid == 16) return false; // neutrinos
    if (pid == 2112) return false; // neutron
    if (pid == 111) return false;  // pi0
    if (pid == 130) return false;  // K0L
    if (pid == 310) return false;  // K0S
    if (pid == 311) return false;  // K0
    if (pid == 3122) return false; // Lambda
    if (pid == 3212) return false; // Sigma0
    if (pid == 3322) return false; // Xi0
    if (pid == 21)  return false;  // gluon
    if (pid == 23)  return false;  // Z boson
    // Charged quarks (fractional - not observable, but in event record)
    if (pid >= 1 && pid <= 6) {
        // u,c,t have charge 2/3; d,s,b have charge 1/3 - all are "charged"
        return true;
    }
    // Leptons
    if (pid == 11 || pid == 13 || pid == 15) return true;
    // Charged mesons/baryons
    if (pid == 211 || pid == 213) return true;  // pi+/-, rho+/-
    if (pid == 321) return true;  // K+/-
    if (pid == 411 || pid == 413) return true;  // D+/-, D*+/-
    if (pid == 431) return true;  // Ds+/-
    if (pid == 2212) return true; // proton
    if (pid == 3222) return true; // Sigma+
    if (pid == 3112) return true; // Sigma-
    if (pid == 3312) return true; // Xi-
    if (pid == 3334) return true; // Omega-
    if (pid == 24) return true;   // W+/-
    // For other particles: use particle data group convention
    // Particles with odd last digit in some schemes are charged
    // Mesons: even last two digits -> neutral, odd -> charged
    // Very rough heuristic for unknown particles:
    // Last digit 0 -> usually neutral
    // This is approximate - for full accuracy use a PDG table
    if (pid > 100) {
        int lastDigit = pid % 10;
        if (lastDigit == 0) return false; // neutral by convention
        // Check for known neutral families
        if (pid % 100 == 11) return false; // neutral mesons like f0, a0...
    }
    return false; // default: neutral for unknowns
}

int main(int argc, char* argv[]) {
    std::string outFileName = "output.root";
    std::string inFileName  = "events.hepmc";

    for (int i = 1; i < argc; ++i) {
        if (std::string(argv[i]) == "-o" && i+1 < argc) outFileName = argv[++i];
        else if (std::string(argv[i]) == "-f" && i+1 < argc) inFileName = argv[++i];
    }

    std::cout << "Input:  " << inFileName  << std::endl;
    std::cout << "Output: " << outFileName << std::endl;

    // Open HepMC2 input
    HepMC::IO_GenEvent hepmcIn(inFileName.c_str(), std::ios::in);

    // Create ROOT output
    TFile* outFile = new TFile(outFileName.c_str(), "RECREATE");
    TTree* tree    = new TTree("tgenBefore", "HepMC event tree");

    // Declare branches (matching main304.cc exactly)
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
    float px_arr[MAXPARTICLE];
    float py_arr[MAXPARTICLE];
    float pz_arr[MAXPARTICLE];
    float pt_arr[MAXPARTICLE];
    float y_arr[MAXPARTICLE];
    float eta_arr[MAXPARTICLE];
    float theta_arr[MAXPARTICLE];
    float phi_arr[MAXPARTICLE];
    float pmag_arr[MAXPARTICLE];
    float mass_arr[MAXPARTICLE];
    float energy_arr[MAXPARTICLE];
    int pdgid_arr[MAXPARTICLE];
    int status_arr[MAXPARTICLE];
    int mother1_arr[MAXPARTICLE];
    int mother2_arr[MAXPARTICLE];
    int daughter1_arr[MAXPARTICLE];
    int daughter2_arr[MAXPARTICLE];
    int pwflag_arr[MAXPARTICLE];
    float weight;

    tree->Branch("eCM",           &eCM,           "eCM/F");
    tree->Branch("sqrt_sHat",     &sqrt_sHat,     "sqrt_sHat/F");
    tree->Branch("mHat",          &mHat,          "mHat/F");
    tree->Branch("totalFinalM",   &totalFinalM,   "totalFinalM/F");
    tree->Branch("nParticle",     &nParticle,     "nParticle/I");
    tree->Branch("isCharged",     ischarged,      "isCharged[nParticle]/O");
    tree->Branch("isNeutral",     isneutral,      "isNeutral[nParticle]/O");
    tree->Branch("passSphericity",&passSphericity,"passSphericity/O");
    tree->Branch("px",            px_arr,         "px[nParticle]/F");
    tree->Branch("py",            py_arr,         "py[nParticle]/F");
    tree->Branch("pz",            pz_arr,         "pz[nParticle]/F");
    tree->Branch("pt",            pt_arr,         "pt[nParticle]/F");
    tree->Branch("pmag",          pmag_arr,       "pmag[nParticle]/F");
    tree->Branch("mass",          mass_arr,       "mass[nParticle]/F");
    tree->Branch("energy",        energy_arr,     "energy[nParticle]/F");
    tree->Branch("y",             y_arr,          "y[nParticle]/F");
    tree->Branch("eta",           eta_arr,        "eta[nParticle]/F");
    // Note: main304.cc has theta branch pointing to eta array (exact replication)
    tree->Branch("theta",         eta_arr,        "theta[nParticle]/F");
    tree->Branch("weight",        &weight,        "weight/F");
    tree->Branch("phi",           phi_arr,        "phi[nParticle]/F");
    tree->Branch("sphericity",    &sphericity,    "sphericity/F");
    tree->Branch("thrust",        &thrust_val,    "thrust/F");
    tree->Branch("polarAngle",    &polarAngle,    "polarAngle/F");
    tree->Branch("pdgid",         pdgid_arr,      "pdgid[nParticle]/I");
    tree->Branch("status",        status_arr,     "status[nParticle]/I");
    tree->Branch("mother1",       mother1_arr,    "mother1[nParticle]/I");
    tree->Branch("mother2",       mother2_arr,    "mother2[nParticle]/I");
    tree->Branch("daughter1",     daughter1_arr,  "daughter1[nParticle]/I");
    tree->Branch("daughter2",     daughter2_arr,  "daughter2[nParticle]/I");
    tree->Branch("pwflag",        pwflag_arr,     "pwflag[nParticle]/I");

    long long nEvents = 0;
    HepMC::GenEvent* evt = hepmcIn.read_next_event();

    while (evt) {
        ++nEvents;
        if (nEvents % 100000 == 0)
            std::cout << "Processing event " << nEvents << std::endl;

        // Get weight
        if (!evt->weights().empty())
            weight = (float)evt->weights()[0];
        else
            weight = 1.0f;

        // Get beam momenta for eCM
        double eBeam1 = 0, eBeam2 = 0;
        if (evt->beam_particles().first)
            eBeam1 = std::fabs(evt->beam_particles().first->momentum().e());
        if (evt->beam_particles().second)
            eBeam2 = std::fabs(evt->beam_particles().second->momentum().e());
        eCM = (float)(eBeam1 + eBeam2);
        if (eCM < 1.0f) eCM = 91.188f; // fallback

        // Collect all particles and build barcode->index map
        std::vector<HepMC::GenParticle*> allParticles;
        std::map<int, int> barcodeToIndex;

        for (HepMC::GenEvent::particle_const_iterator pit = evt->particles_begin();
             pit != evt->particles_end(); ++pit) {
            barcodeToIndex[(*pit)->barcode()] = (int)allParticles.size();
            allParticles.push_back(*pit);
        }

        // Find the Z boson (pdgid=23) for mHat (hard process invariant mass)
        // This matches Pythia's pythia.info.mHat() which gives the resonance mass
        double zMass = -1.0;
        for (auto* p : allParticles) {
            if (p->pdg_id() == 23) {
                zMass = p->momentum().m();
                break;
            }
        }

        // Calculate final-state quantities for thrust and sphericity
        std::vector<TVector3> finalMomenta;
        FourVec totalFourVec;
        FourVec hadronicFourVec;  // excludes forward photons (ISR candidates)

        for (auto* p : allParticles) {
            if (p->status() == 1) { // final state
                TVector3 mom3(p->momentum().px(), p->momentum().py(), p->momentum().pz());
                finalMomenta.push_back(mom3);
                FourVec lv(p->momentum().px(), p->momentum().py(),
                           p->momentum().pz(), p->momentum().e());
                totalFourVec += lv;

                // Exclude forward photons (|eta|>5) from hadronic sum (ISR photons)
                double pxv = p->momentum().px(), pyv = p->momentum().py();
                double pzv = p->momentum().pz();
                double pmag = std::sqrt(pxv*pxv+pyv*pyv+pzv*pzv);
                double abseta = 999;
                if (pmag > 1e-10 && std::fabs(pmag - std::fabs(pzv)) > 1e-20)
                    abseta = std::fabs(0.5*std::log((pmag+pzv)/(pmag-pzv)));
                bool isForwardPhoton = (p->pdg_id() == 22 && abseta > 5.0);
                if (!isForwardPhoton) {
                    hadronicFourVec += lv;
                }
            }
        }

        // mHat priority: (1) Z boson mass, (2) hadronic system mass (no ISR photons)
        totalFinalM = (float)totalFourVec.M();
        if (zMass > 0) {
            mHat      = (float)zMass;
            sqrt_sHat = (float)zMass;
        } else {
            mHat      = (float)hadronicFourVec.M();
            sqrt_sHat = mHat;
        }

        // Thrust
        thrust_val = (float)calcThrust(finalMomenta);

        // Sphericity
        SphericityResult sphRes = calcSphericity(finalMomenta);
        sphericity = (float)sphRes.sphericity;
        float polAngle = (float)std::acos(
            std::max(-1.0, std::min(1.0, (double)sphRes.axis1.Z())));
        polarAngle = polAngle;
        float spherLow  = 7.0f * (float)M_PI / 36.0f;
        float spherHigh = 29.0f * (float)M_PI / 36.0f;
        passSphericity = (polAngle > spherLow && polAngle < spherHigh);

        // Fill particle arrays - all particles (like main304.cc)
        nParticle = 0;
        int maxIdx = (int)allParticles.size();
        if (maxIdx > MAXPARTICLE) maxIdx = MAXPARTICLE;

        for (int i = 0; i < maxIdx; ++i) {
            HepMC::GenParticle* p = allParticles[i];
            const HepMC::FourVector& mom = p->momentum();

            double pxv  = mom.px();
            double pyv  = mom.py();
            double pzv  = mom.pz();
            double ev   = mom.e();
            double mv   = mom.m();
            double pmagv = std::sqrt(pxv*pxv + pyv*pyv + pzv*pzv);
            double ptv   = std::sqrt(pxv*pxv + pyv*pyv);

            // pseudorapidity
            double etav;
            if (pmagv > 1e-10 && std::fabs(pmagv - std::fabs(pzv)) > 1e-20)
                etav = 0.5*std::log((pmagv + pzv)/(pmagv - pzv));
            else
                etav = (pzv > 0) ? 1e9 : -1e9;

            double thetav = (pmagv > 1e-10) ?
                std::acos(std::min(1.0, std::max(-1.0, pzv/pmagv))) : 0.0;
            double phiv  = std::atan2(pyv, pxv);

            // rapidity
            double yv;
            if (ev > 1e-10 && std::fabs(ev - std::fabs(pzv)) > 1e-20)
                yv = 0.5*std::log((ev + pzv)/(ev - pzv));
            else
                yv = (pzv > 0) ? 1e9 : -1e9;

            px_arr[i]     = (float)pxv;
            py_arr[i]     = (float)pyv;
            pz_arr[i]     = (float)pzv;
            pt_arr[i]     = (float)ptv;
            pmag_arr[i]   = (float)pmagv;
            mass_arr[i]   = (float)mv;
            energy_arr[i] = (float)ev;
            eta_arr[i]    = (float)etav;
            theta_arr[i]  = (float)thetav;
            phi_arr[i]    = (float)phiv;
            y_arr[i]      = (float)yv;
            pdgid_arr[i]  = p->pdg_id();
            status_arr[i] = p->status();

            bool chg = isChargedParticle(p->pdg_id());
            ischarged[i] = chg ? kTRUE : kFALSE;
            isneutral[i] = chg ? kFALSE : kTRUE;

            // Mother/daughter info via HepMC vertices
            mother1_arr[i]   = 0;
            mother2_arr[i]   = 0;
            daughter1_arr[i] = 0;
            daughter2_arr[i] = 0;

            if (p->production_vertex()) {
                HepMC::GenVertex* pv = p->production_vertex();
                int nm = 0;
                for (HepMC::GenVertex::particle_iterator it =
                         pv->particles_begin(HepMC::parents);
                     it != pv->particles_end(HepMC::parents); ++it) {
                    auto jt = barcodeToIndex.find((*it)->barcode());
                    if (jt != barcodeToIndex.end()) {
                        if (nm == 0) mother1_arr[i] = jt->second;
                        else         mother2_arr[i] = jt->second;
                    }
                    ++nm;
                }
            }

            if (p->end_vertex()) {
                HepMC::GenVertex* ev_vtx = p->end_vertex();
                int nd = 0;
                for (HepMC::GenVertex::particle_iterator it =
                         ev_vtx->particles_begin(HepMC::children);
                     it != ev_vtx->particles_end(HepMC::children); ++it) {
                    auto jt = barcodeToIndex.find((*it)->barcode());
                    if (jt != barcodeToIndex.end()) {
                        if (nd == 0) daughter1_arr[i] = jt->second;
                        else         daughter2_arr[i] = jt->second;
                    }
                    ++nd;
                }
            }

            // pwflag is now derived from pdgid in Analyze.cxx (pwflagFromPdgId)

            ++nParticle;
        }

        tree->Fill();

        delete evt;
        evt = hepmcIn.read_next_event();
    }

    std::cout << "Processed " << nEvents << " events." << std::endl;
    tree->Write();
    delete outFile;
    return 0;
}
