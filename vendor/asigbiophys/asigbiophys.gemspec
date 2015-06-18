Gem::Specification.new do |s|
  s.name = %q{asigbiophys}
  s.version = "0.1.4"
  s.date = %q{2011-05-31}
  s.authors = ["Paul Kaarakka","Rick Wayne"]
  s.email = %q{fewayne@wisc.edu}
  s.summary = %q{ASIGBiophys provides biophysical calculators for use in agriculture and related disciplines.}
  s.homepage = %q{http://www.soils.wisc.edu/asig/ASIG.software/}
  s.description =<<-END
   ASIGBiophys provides biophysical calculators for use in agriculture and related disciplines. In particular, there are
   two irrigation-related calculators in here, one for allowable depletion (AD) "checkbook" calculations and one for 
   calculating an adjusted evapotranspiration (ET) from a reference ET and some phenological information. As of this writing,
   there is a percent-cover empiricism, and one derived from corn plants that uses a crop growth curve based on leaf area index
   (LAI) measurements.
   END
  s.files = [ "README", "CHANGELOG", "LICENSE", "lib/asigbiophys.rb", "lib/ad_calculator.rb", "lib/et_calculator.rb",
              "Rakefile", "test/test_ad.rb", "test/test_et.rb"]
end
