Random:setSeed = on
Random:seed = 12345
Main:numberOfEvents = 10           ! number of events to generate
Main:timesAllowErrors = 5          ! how many aborts before run stops

! 2) Settings related to output in init(), next() and stat().
Init:showChangedSettings = on      ! list changed settings
Init:showChangedParticleData = off ! list changed particle data
Next:numberCount = 100             ! print message every n events
Next:numberShowInfo = 1            ! print event information n times
Next:numberShowProcess = 1         ! print process record n times
Next:numberShowEvent = 0           ! print event record n times

# --- 10 TeV muon collider ---
Beams:idA = 13          ! mu- beam
Beams:idB = -13         ! mu+ beam
Beams:eCM = 10000       ! 10 TeV CM energy (units are GeV)

PartonLevel:ISR = on
PartonLevel:FSR = on

Top:ffbar2ttbar(s:gmZ) = on
