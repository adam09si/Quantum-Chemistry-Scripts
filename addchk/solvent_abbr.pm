#!/usr/bin/env perl

# PLACE THIS FILE IN THE SAME DIRECTORY AS addchk.pl

package Solvents;
use strict;
use warnings;

sub abbreviations {
	my %solv = (
		# Add your own synonyms here
		# The abbreviated forms must be in ALLCAPS
		H2O => 'water',
		ACN => 'acetonitrile',
		CH3CN => 'acetonitrile',
		MECN => 'acetonitrile',
		CH3OH => 'methanol',
		MEOH => 'methanol',
		CH3CH2OH => 'ethanol',
		ETOH => 'ethanol',
		CHCL3 => 'chloroform',
		ET2O => 'diethylether',
		ETHER => 'diethylether',
		DCM => 'dichloromethane',
		CH2CL2 => 'dichloromethane',
		CCL4 => 'CarbonTetraChloride',
		C6H6 => 'benzene',
		PHCL => 'chlorobenzene',
		CH3NO2 => 'nitromethane',
		MENO2 => 'nitromethane',
		PHNH2 => 'aniline',
		THF => 'tetrahydrofuran',
		DMSO => 'dimethylsulfoxide',
		AR => 'argon',
		KR => 'krypton',
		XE => 'xenon',
		NBUOH => '1-butanol',
		NPROH => '1-propanol',
		IPROH => '2-propanol',
		IPA => '2-propanol',
		CH3CO2H => 'AceticAcid',
		CH3COOH => 'AceticAcid',
		ACOH => 'AceticAcid',
		PHOME => 'anisole',
		PHCHO => 'benzaldehyde',
		PHCN => 'benzonitrile',
		CHBR3 => 'bromoform',
		CS2 => 'CarbonDisulfide',
		ETOAC => 'EthylEthanoate',
		ETHYLACETATE=>'EthylEthanoate',
		ETSH => 'ethanethiol',
		PHET => 'ethylbenzene',
		HEXANE => 'n-hexane',
		PHME => 'toluene',
	);
	return %solv;
}

1;
