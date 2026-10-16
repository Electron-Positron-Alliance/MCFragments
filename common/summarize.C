// summarize.C: reference numbers for a tgenBefore ntuple, to compare a new installation with the values in each
// SETUP.md.  root -l -b -q 'summarize.C("file.root")'   (optional second argument: only the first N events)
void summarize(const char* file, long long nmax = -1) {
  ROOT::RDataFrame all("tgenBefore", file);
  auto d = nmax > 0 ? ROOT::RDF::RNode(all.Range(nmax)) : ROOT::RDF::RNode(all);
  auto n = d.Count();
  auto first = d.Range(1).Take<float>("thrust");
  auto t = d.Mean<float>("thrust");
  auto np = d.Mean<int>("nParticle");
  auto nch = d.Define("nch", "(int)Sum(isCharged)").Mean<int>("nch");
  printf("events %lld  thrust(event 0) %.6f  <thrust> %.6f  <nParticle> %.4f  <sum isCharged> %.4f\n",
         (long long)*n, first->at(0), *t, *np, *nch);
}
