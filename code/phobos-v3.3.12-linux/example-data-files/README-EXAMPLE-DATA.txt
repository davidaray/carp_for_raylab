Example FASTA files that come with Phobos:
==========================================

File: example-alternative-alignment-manual-1-6bp.fasta
------------------------------------------------------
Most repeat detection programs which search for
imperfect repeats detect the wrong repeat here.


File: example-alternative-alignment-1-6bp.fasta
------------------------------------------------------
Most repeat detection programs which search for
imperfect repeats detect the wrong repeat here.


File: examples-imperfect-1-60bp.fasta
------------------------------------------------------
A file with a collection of microsatellite containing
inserts enriched with the reporter genome protocol
(see Leese, Mayer Held, Isolation of microsatellites
from unknown genomes using known genomes as enrichment
templates, submitted).
The repeats have a pattern size between 1-57bp.


File: example-extendExact-1-5000bp.fasta
------------------------------------------------------
A file with long repeats with a repeat patterns size between
1000-5000bp taken from the "homo sapiens" genome.
An imperfect search in this pattern size range is too slow
in the current version of Phobos.
Reasonable search parameters are:
- imperfect search, pattern size range 1-60, gap and mismatch
  penalty -6
- extend exact search, pattern size range 1-5000, gap and
  mismatch penalty -6 to -4.






