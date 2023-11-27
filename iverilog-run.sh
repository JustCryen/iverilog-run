#! /bin/bash

dir=$(pwd)
cd "$dir"

if ! [ -d "$dir/output" ]; then
	echo -e "Created an output dir.\t" 
	mkdir output
fi

if [ -f "$dir/output/save" ]; then
	read -p 'Do you want to exec the save file? [Y/n]: ' save
	case $save in
		[nN] | [nN][oO])
			;;
		[yY] | [yY][eE][sS] | *)
				exec "$dir/output/save" "$1" >&2; exit 1
			;;
	esac
fi

echo  "iverilog -o output/<file>.vvp <files>.v"
read -ep 'Output file name: ' vvp_name
read -ep 'verilog files: ' v_files
echo ""

echo -e "> iverilog -o output/$vvp_name.vvp $v_files\n"
command="iverilog -Wall -o output/$vvp_name.vvp $v_files"
iverilog -Wall -o output/$vvp_name.vvp $v_files || exit 1


if [ -f "$dir/output/$vvp_name.lxt" ]; then
  rm "$dir/output/$vvp_name.lxt"
fi


echo -e "> vvp output/$vvp_name.vvp\n"
command="$command && vvp output/$vvp_name.vvp -lxt2"
vvp output/$vvp_name.vvp -lxt2 || exit 1

echo -e "\n> gtkwave output/$vvp_name.lxt"
render="gtkwave output/$vvp_name.lxt output/$vvp_name.gtkw >> /dev/null & disown && sleep 2 && echo ''"
if ! [[ $1 == "-q" ]]; then
	gtkwave output/$vvp_name.lxt output/$vvp_name.gtkw >> /dev/null & disown && sleep 2 && echo ''
else
	echo ""
fi

read -ep 'Do you want to save the config file? [y/N]: ' save
case $save in
	[yY] | [yY][eE][sS])
		if [ -f "$dir/output/save" ]; then
			read -p 'Overwrite the save file? [y/N]: ' overwrite
			case $overwrite in
				[yY] | [yY][eE][sS])
					;;
				[nN] | [nN][oO] | *)
					echo "Aborted" && exit 1
					;;
			esac
		fi
		echo -e "#! /bin/bash\n" > "$dir/output/save"
		echo -e "rm '$dir/output/$vvp_name.lxt'" >> "$dir/output/save"
		echo -e "$command" >> "$dir/output/save"
		echo 'if ! [[ $1 == "-q" ]]; then' >> "$dir/output/save"
		echo -e "\t$render" >> "$dir/output/save"
		echo -e "fi" >> "$dir/output/save"
		chmod +x "$dir/output/save" & echo "Saved"
		;;
	[nN] | [nN][oO] | *)
		;;
esac
