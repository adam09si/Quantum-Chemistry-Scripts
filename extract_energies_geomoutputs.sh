for i in *.out; do
	echo $i >> Results.txt
	g09_getenergies.py $i >> Results.txt
	echo "**********************" >> Results.txt
done
