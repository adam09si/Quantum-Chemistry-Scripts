for i in *.com; do
	j=`basename $i .com`
	cp temp.cmd $j.cmd
	sed -i "s/temp/$j/g" $j.cmd
done
