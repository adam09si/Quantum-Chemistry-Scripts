for i in *.out; do
	j=`basename $i .out`
	cp method.com $j'SP'.com
	addchk.pl -i $j'SP'.com -o $i
done
