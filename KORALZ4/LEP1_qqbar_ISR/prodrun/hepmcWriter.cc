// HEPEVT (KORALZ/TAUOLA layout: NMXHEP=2000, single precision) -> HepMC3 Asciiv3 in the layout
// hadronizeKKMC reads: beams status 4, q / qbar / ISR photons status 1. Called from MainKoralzHepMC.f.
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

#include "HepMC3/GenEvent.h"
#include "HepMC3/GenParticle.h"
#include "HepMC3/GenVertex.h"
#include "HepMC3/WriterAscii.h"

extern "C" {
extern struct {
  int nevhep, nhep, isthep[2000], idhep[2000], jmohep[2000][2], jdahep[2000][2];
  float phep[2000][5], vhep[2000][4];
} hepevt_;
}

static std::unique_ptr<HepMC3::WriterAscii> writer;

static void fail(const std::string& msg) {
  std::fprintf(stderr, "hepmcWriter: %s\n", msg.c_str());
  std::exit(3);
}

extern "C" void hepmcopen_(const char* path, size_t len) {
  std::string p(path, len);
  p.erase(p.find_last_not_of(' ') + 1);
  writer = std::make_unique<HepMC3::WriterAscii>(p);
  if (writer->failed()) fail("cannot open " + p);
}

extern "C" void hepmcwrite_(const int* iev) {
  HepMC3::GenEvent ev(HepMC3::Units::GEV, HepMC3::Units::MM);
  ev.set_event_number(*iev);
  auto vtx = std::make_shared<HepMC3::GenVertex>();
  int nBeam = 0, nQ = 0, nQb = 0;
  for (int i = 0; i < hepevt_.nhep; ++i) {
    const float* p = hepevt_.phep[i];
    const int id = hepevt_.idhep[i], st = hepevt_.isthep[i];
    const double px = p[0], py = p[1], pz = p[2], m = p[4];
    if (st == 3) {  // beams
      vtx->add_particle_in(std::make_shared<HepMC3::GenParticle>(
          HepMC3::FourVector(px, py, pz, p[3]), id, 4));
      ++nBeam;
    } else if (st == 1) {
      // Energy recomputed on shell in double precision: HEPEVT stores single-precision momenta, and
      // hadronizeKKMC takes the parton mass from E^2-p^2 (light quarks would otherwise lose ~2%).
      const double e = std::sqrt(px * px + py * py + pz * pz + m * m);
      vtx->add_particle_out(std::make_shared<HepMC3::GenParticle>(
          HepMC3::FourVector(px, py, pz, e), id, 1));
      if (id >= 1 && id <= 5) ++nQ;
      if (id <= -1 && id >= -5) ++nQb;
      if (std::abs(id) > 5 && id != 22) fail("unexpected final-state pdg " + std::to_string(id));
    }
  }
  if (nBeam != 2 || nQ != 1 || nQb != 1)
    fail("event " + std::to_string(*iev) + ": expected 2 beams, 1 q, 1 qbar");
  ev.add_vertex(vtx);
  writer->write_event(ev);
}

extern "C" void hepmcclose_() { writer->close(); }
