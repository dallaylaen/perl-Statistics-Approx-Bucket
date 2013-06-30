#!/bin/sh

PERLS="5.6.0 5.8.8 5.18.0"

die () {
	echo "FATAL: $1" >&2
	exit 1
}

perlbrew switch-off
perl --version | grep "^This is"

perl Makefile.PL || die "perl makefile fails"
make || die "make fails"
VER=`perl -MYAML=LoadFile -we 'print LoadFile(shift)->{version}' MYMETA.yml`
[ -z "$VER" ] && die "No version found" 

echo "Version $VER..."

# only can make dist on commit border
[ -z "`git status -s`" ] || die "Uncommitted changes present"

# check make test on several perls
FAILS=
for i in $PERLS; do
	perlbrew switch "$i" || continue
	prove -I lib t/ || FAILS="$FAILS $i"
done

perlbrew switch-off
prove -I lib t/ || FAILS="$FAILS system-perl"

[ \! -z "$FAILS" ] && die "Tests failed under perls $FAILS"

grep "^[ \t]*$VER" Changes || die "Version $VER not present in Changes"
