az login -u gallen@cudazure.onmicrosoft.com -p 


#get subscriptions

SUBSCRIPTIONS=`az account list --all --output tsv`

while read cloudname sub isdefault subname enabled tenant
do
	echo $sub $subname 
done < `$SUBSCRIPTIONS`



while IFS=$'\t' read -r -a myArray
do
 echo "${myArray[0]}"
 echo "${myArray[1]}"
 echo "${myArray[2]}"
done < myfile

#Get route tables

az network route-table list
