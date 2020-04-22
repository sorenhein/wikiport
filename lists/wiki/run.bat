set dd = "raw"
set jk = "list.txt"
set out = "ordered"

set temp1 = ${dd}/list1.txt
set temp2 = ${dd}/list2.txt

cp ${dd}/list.txt ${temp1}

foreach i (categories/*)
  set b = `basename $i .txt`
  echo "Running $b"
  perl split2.pl ${temp1} $i ${out}/$b > ${temp2}
  mv ${temp2} ${temp1}
end

echo "Left over:"
wc ${temp1} 
echo "Found:"
foreach i (ordered/*)
  echo $i
  cat $i/* | wc
end
echo "Found total:"
cat ordered/*/* | wc
echo ""
echo "vs."
echo ""
wc ${dd}/${jk}
