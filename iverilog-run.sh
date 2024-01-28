#! /bin/bash

save_file=$(echo -e "$(pwd)/output/save")

if ! [ -d "$(pwd)/output" ]; then
	read -p "create an output dir? [y/N]: " output
	case $output in
		[yY] | [yY][eE][sS])
			mkdir output
			echo -e "Created an output dir.\t" 
		;;
		[nN] | [nN][oO] | *)
			echo "Aborted" && exit 1
		;;
	esac
fi

if [ -f "$save_file" ]; then
	read -p 'Do you want to exec the save file? [Y/n]: ' save
	case $save in
		[nN] | [nN][oO])
			;;
		[yY] | [yY][eE][sS] | *)
				exec "$save_file" "$1" >&2; exit 1
			;;
	esac
fi

echo "iverilog -o output/<file>.vvp <files>.v"
read -ep 'Output file name: ' vvp_name
read -ep 'verilog files: ' v_files
echo ""

#lxt_file=$(echo -e "$(pwd)/output/$vvp_name.lxt")
lxt_file=$(echo -e "output/\$vvp_name.lxt")

echo -e "> iverilog -o output/$vvp_name.vvp $v_files\n"
command="iverilog -Wall -o output/\$vvp_name.vvp $v_files"
iverilog -Wall -o output/$vvp_name.vvp $v_files # || exit 1


if [ -f "$lxt_file" ]; then
  rm "$lxt_file"
fi


echo -e "> vvp output/$vvp_name.vvp\n"
command="$command && vvp output/\$vvp_name.vvp -lxt2"
vvp output/$vvp_name.vvp -lxt2 # || exit 1

echo -e "\n> gtkwave output/$vvp_name.lxt"
render="gtkwave output/\$vvp_name.lxt output/\$vvp_name.gtkw >> /dev/null & disown && sleep 2 && echo ''"
if ! [[ $1 == "-q" ]]; then
	gtkwave output/$vvp_name.lxt output/$vvp_name.gtkw >> /dev/null & disown && sleep 2 && echo ''
else
	echo ""
fi

read -ep 'Do you want to save the config file? [y/N]: ' save
case $save in
	[yY] | [yY][eE][sS])
		if [ -f "$save_file" ]; then
			read -p 'Overwrite the save file? [y/N]: ' overwrite
			case $overwrite in
				[yY] | [yY][eE][sS])
					;;
				[nN] | [nN][oO] | *)
					echo "Aborted" && exit 1
					;;
			esac
		fi
		echo -e "#! /bin/bash\n"				>  "$save_file"
		echo "if [[ \$2 == \"\" ]]; then"		>> "$save_file"
		echo -e "\tvvp_name=$vvp_name"			>> "$save_file"
		echo "else"								>> "$save_file"
		echo -e "\tvvp_name=\$2"				>> "$save_file"
		echo "fi"								>> "$save_file"
		echo -e "if [ -f $lxt_file ]; then"		>> "$save_file"
		echo -e "\trm $lxt_file"				>> "$save_file"
		echo "fi"								>> "$save_file"
		echo -e "$command"						>> "$save_file"
		echo 'if ! [[ $1 == "-q" ]]; then'		>> "$save_file"
		echo -e "\t$render"						>> "$save_file"
		echo "fi"								>> "$save_file"
		chmod +x "$save_file" & echo "Saved"
		;;
	[nN] | [nN][oO] | *)
		;;
esac
