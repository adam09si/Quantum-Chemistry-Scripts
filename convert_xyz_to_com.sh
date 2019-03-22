for i in *.xyz; do
	perl xyz2com.pl  $i -l "b3lyp 6-31G(d) opt=modredundant" 
done
