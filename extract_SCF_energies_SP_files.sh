if [[ -e SP_files.txt ]]; then
	rm -f SP_files.txt
fi

for i in *SP.out; do
	echo -n "$i	" >> SP_files.txt
	grep 'SCF Done' $i >> SP_files.txt
done

perl -i.bak -pe 's/SCF.*= *//; s/ A\.U\..*cycles$//' SP_files.txt
