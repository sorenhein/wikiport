set dd = "2020-04-13-10-00"
set jk = "j0.txt"
set out = "ordered"

echo "Fixing special characters"
perl clean.pl ${dd}/${jk} | sort > ${dd}/list.txt

set temp1 = ${dd}/list1.txt
set temp2 = ${dd}/list2.txt

cp ${dd}/list.txt ${temp1}

foreach i (categories/*)
  set b = `basename $i .txt`
  echo "Running $b"
  perl split.pl ${temp1} $i ${out}/$b > ${temp2}
  mv ${temp2} ${temp1}
end

wc ${temp1} ${out}/*/*.txt
echo ""
echo "vs."
echo ""
wc ${dd}/${jk}
