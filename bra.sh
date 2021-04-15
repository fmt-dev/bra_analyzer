
#!/bin/bash

#new project 
prefix='BRA'
declare -a file_ext=( 'xml' 'pdf')
declare -a nb_days=( 31 29 31 30 31 30 31 31 30 31 30 31 ) # we do not handle leap year...
declare -a massif_arr=( 'ORLU__ST_BARTHELEMY')
#declare -a massif_arr=( 'HAUTE-ARIEGE')
hour_last='20'
year_start='2019'
month_start='11'
day_start='2'
hour_start='12'
min_start='0'
sec_start='0'
nb_data_max=-1
base_wd=/media/ssd1tb/bra
repo_path="https://donneespubliques.meteofrance.fr/donnees_libres/Pdf/BRA/"
spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"
acc_file=acc
integ_file=integ
limit_file=limit

rm $acc_file
rm $integ_file
rm $limit_file

curr_year=$year_start
curr_month=$month_start
curr_day=$day_start

# results array
declare -A pentes_danger
pentes_danger[e]=0
pentes_danger[se]=0
pentes_danger[w]=0
pentes_danger[sw]=0
pentes_danger[nw]=0
pentes_danger[ne]=0
pentes_danger[n]=0
pentes_danger[s]=0

declare -A pentes_risk
pentes_risk[e]=0
pentes_risk[se]=0
pentes_risk[w]=0
pentes_risk[sw]=0
pentes_risk[nw]=0
pentes_risk[ne]=0
pentes_risk[n]=0
pentes_risk[s]=0

function build_name()
{
    y=$1
    mo=$2
    d=$3
    h=$4
    mi=$5
    s=$6

    while [[ ${#mo} -lt 2 ]] ; do
	mo="0${mo}"
    done

    while [[ ${#d} -lt 2 ]] ; do
	d="0${d}"
    done

    while [[ ${#h} -lt 2 ]] ; do
	h="0${h}"
    done

    while [[ ${#mi} -lt 2 ]] ; do
	mi="0${mi}"
    done

    while [[ ${#s} -lt 2 ]] ; do
	s="0${s}"
    done

    name=$y$mo$d$h$mi$s

    echo "$name"
}

function build_date()
{
    y=$1
    mo=$2
    d=$3

    while [[ ${#mo} -lt 2 ]] ; do
	mo="0${mo}"
    done

    while [[ ${#d} -lt 2 ]] ; do
	d="0${d}"
    done

    date=$y$mo$d

    echo "$date"
}


function remote_file_exist()
{
    name=$1
    massif=$2

    exist=0

    wget -q --spider $repo_path$prefix.$massif.$name.xml

    if [ $? -eq 0 ]; then
	exist=1
    fi

    echo "$exist"
}

function local_file_exist()
{
    massif=$1
    date=$2
    dir=$3
    file_pattern=$prefix.$massif.$date*.xml

    exist=""

    if [ -f $base_wd/$massif/$file_pattern ]; then
	# echo "file $file_pattern exist in $dir" >&2
	path=`find $dir -name *$date*.xml`
	#echo "toto $path" >&2
	toto=${path#"$base_wd/$massif/BRA.$massif."}
	#echo "$toto" >&2
	exist=${toto%".xml"}
	#echo "$exist" >&2
    fi

    echo "$exist"
}

function get_file()
{
    local wd=$1
    local path=$2

    # get file from url to path
    wget -q $url -O $path
}

function create_wd()
{
    local wd
    local massif=$1

    wd=$base_wd/$massif

    # create working directory
    # -p option for parents creation
    mkdir -p $wd

    echo "$wd"
}

function find_data()
{
    massif=$1

    name=""
    sp="/-\|"
    
    for hr in $( seq $hour_start $hour_last ); do
	for mi in $( seq $min_start 59 ); do
	    for sec in $( seq $sec_start 59 ); do
		name_tmp=$(build_name $curr_year $curr_month $curr_day $hr $mi $sec)
		a=$(($((${sec}-${sec_start}))+$((${mi}-${min_start}))*60+$((${hr}-${hour_start}))*3600))
		diff_hr_max=$((${hour_last}-${hour_start}))
		b=$((${diff_hr_max}*3600))
		p=$((${a}*100/${b}))
		echo -ne "${spin[$((${sec}%4))]} ${p}%\r" >&2
		# echo "$name_tmp ${p}">&2
		if [ $(remote_file_exist $name_tmp $massif) -ne 0 ]; then
		    echo "found $name_tmp" >&2
		    name=$name_tmp
		    break 3;
		fi
	    done
	done
    done

    # echo "nothing found" >&2
    echo $name
}

function convert_xml()
{
    file=$1

    sed -i 's/\&\#233;/é/g' $file
    sed -i 's/\&\#232;/è/g' $file
    sed -i 's/\&\#224;/à/g' $file
    sed -i 's/\&\#234;/ê/g' $file
}

function retrieve_data()
{
    xml_data2=$1
    massif=$2
    prefix=$3

    file_name="$prefix.$massif.$xml_data2"
    wd=$(create_wd $massif)

    for i in $(seq 0 $(($nb_ext-1)))
    do
	file=$file_name.${file_ext[$i]}
	url="$repo_path/$file"

	get_file $url $wd/$file

	if [ "${file_ext[$i]}" = 'xml' ]; then
	    xml_path=$wd/$file
	fi

    done

    echo $xml_path
}

function extract_xml()
{
    xml_file=$1

    echo "Parsing xml file $xml_file"

    data_dump[alt_r]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/RISQUE/@ALTITUDE)' $xml_file)
    data_dump[loc1]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/RISQUE/@LOC1)' $xml_file)
    data_dump[loc2]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/RISQUE/@LOC2)' $xml_file)
    data_dump[pente_ne]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@NE)' $xml_file)
    data_dump[pente_e]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@E)' $xml_file)
    data_dump[pente_se]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@SE)' $xml_file)
    data_dump[pente_s]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@S)' $xml_file)
    data_dump[pente_sw]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@SW)' $xml_file)
    data_dump[pente_w]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@W)' $xml_file)
    data_dump[pente_nw]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@NW)' $xml_file)
    data_dump[pente_n]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/PENTE/@N)' $xml_file)
    data_dump[nat_r]=$(xmllint --xpath '//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/RESUME/text()' $xml_file)
    data_dump[limite_s]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/ENNEIGEMENT/@LimiteSud)' $xml_file)
    data_dump[limite_n]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/ENNEIGEMENT/@LimiteNord)' $xml_file)
    data_dump[risk_1]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/RISQUE/@RISQUE1)' $xml_file)
    data_dump[risk_2]=$(xmllint --xpath 'string(//Bulletins/BULLETINS_NEIGE_AVALANCHE/CARTOUCHERISQUE/RISQUE/@RISQUE2)' $xml_file)

    if [ "${data_dump[risk_1]}" == "-1" ]; then
	data_dump[risk_1]=0
    fi

    if [ "${data_dump[pente_n]}" = true ]; then
	pentes_danger[n]=$((pentes_danger[n]+data_dump[risk_1]))
	pentes_risk[n]=${data_dump[risk_1]}
    else
	pentes_risk[n]=0
    fi

    if [ "${data_dump[pente_s]}" = true ]; then
	pentes_danger[s]=$((pentes_danger[s]+data_dump[risk_1]))
	pentes_risk[s]=${data_dump[risk_1]}
    else
	pentes_risk[s]=0
    fi

    if [ "${data_dump[pente_e]}" = true ]; then
	pentes_danger[e]=$((pentes_danger[e]+data_dump[risk_1]))
	pentes_risk[e]=${data_dump[risk_1]}
    else
	pentes_risk[e]=0
    fi

    if [ "${data_dump[pente_w]}" = true ]; then
	pentes_danger[w]=$((pentes_danger[w]+data_dump[risk_1]))
	pentes_risk[w]=${data_dump[risk_1]}
    else
	pentes_risk[w]=0
    fi

    if [ "${data_dump[pente_nw]}" = true ]; then
	pentes_danger[nw]=$((pentes_danger[nw]+data_dump[risk_1]))
    fi

    if [ "${data_dump[pente_ne]}" = true ]; then
	pentes_danger[ne]=$((pentes_danger[ne]+data_dump[risk_1]))
    fi

    if [ "${data_dump[pente_sw]}" = true ]; then
	pentes_danger[sw]=$((pentes_danger[sw]+data_dump[risk_1]))
    fi

    if [ "${data_dump[pente_se]}" = true ]; then
	pentes_danger[se]=$((pentes_danger[se]+data_dump[risk_1]))
    fi
    
    
    echo "accumulated and ponderated result is ${pentes_danger[n]} !!!!!!!"


    
}

function create_csv()
{
    csv_file=$1

    echo "date,data1,data2" > $csv_file
}

function fill_csv()
{
    date=$1
    csv_file=$2

    csv_string="$date,${data_dump[alt_r]},${data_dump[nat_r]},${data_dump[loc1]}"

    # go to last line
    sed -i -e "\$a $csv_string" $csv_file
}

function goto_nextday()
{
    curr_day=$((curr_day+1))

    if (($curr_day > ${nb_days[${curr_month}-1]})); then
	curr_month=$((curr_month+1))
	curr_day=1
    fi

    if (($curr_month > 12)); then
	curr_year=$((curr_year+1))
	curr_month=1
    fi
}

declare nb_ext=${#file_ext[@]}
declare nb_massif=${#massif_arr[@]}
declare -A data_dump
declare csv_file=$base_wd/toto.csv

# script starts here
create_csv $csv_file

nb_data=0

for i in $(seq 0 $(($nb_massif-1))) ; do
    # check if data is available
    while(( $nb_data < $nb_data_max )) || [[ $nb_data_max == -1  ]]; do

	date=$(build_date $curr_year $curr_month $curr_day)
	dir=$base_wd/$massif
	xml_data=$(local_file_exist ${massif_arr[$i]} $date $dir)
	skip=0
	if [ ! -z $xml_data ]; then
    	    echo "data for ${massif_arr[$i]} at date $date already available in $dir" >&2
	    echo "fsdfdsfsdfsdfdssds $xml_data"
    	else
	    skip=1
	    echo "Looking for data for ${massif_arr[$i]} for $curr_year/$curr_month/$curr_day ..."

	    # loop for spidering data server on target day
	    if [ $skip -eq 0 ]; then
		xml_data=""
		xml_data=$(find_data ${massif_arr[$i]})
	    fi
	fi

	if [ $skip -eq 0 ]; then
	    if [ -n "$xml_data" ] ; then
		echo "Found data $xml_data on ${massif_arr[$i]}"

		nb_data=$((nb_data+1))

		xml_file=$(retrieve_data $xml_data ${massif_arr[$i]} $prefix)

		# remove xml special characters
		convert_xml $xml_file

		# extract data
		extract_xml $xml_file
		fill_csv $xml_data $csv_file
	    else
		echo "No data found"
	    fi
	fi

	# go to next day
	goto_nextday

	echo "${pentes_danger[n]} ${pentes_danger[s]} ${pentes_danger[e]} ${pentes_danger[w]} $nb_data" >> $acc_file
	echo "${pentes_risk[n]} ${pentes_risk[s]} ${pentes_risk[e]} ${pentes_risk[w]}" >> $integ_file
	echo "${data_dump[limite_n]} ${data_dump[limite_s]}" >> $limit_file

    done



done
