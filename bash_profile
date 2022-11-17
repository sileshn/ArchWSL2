# First run script for ArchWSL.

blu=$(tput setaf 4)
cyn=$(tput setaf 6)
grn=$(tput setaf 2)
mgn=$(tput setaf 5)
red=$(tput setaf 1)
ylw=$(tput setaf 3)
txtrst=$(tput sgr0)

diskvol=$(mount | grep -m1 ext4 | cut -f 1 -d " ")
sudo resize2fs $diskvol >/dev/null 2>&1
disksize=$(sudo blockdev --getsize64 $diskvol)
width=$(echo $COLUMNS)

if [ "$width" -gt 120 ]; then
    width=120
fi

test -e /mnt/c/Users/Public/vhdresize.txt && rm /mnt/c/Users/Public/vhdresize.txt
test -e /mnt/c/Users/Public/shutdown.cmd && rm /mnt/c/Users/Public/shutdown.cmd
test -e ~/vhdresize.txt && rm ~/vhdresize.txt
test -e ~/shutdown.cmd && rm ~/shutdown.cmd
figlet -t -k -f /usr/share/figlet/fonts/mini.flf "Welcome to ArchWSL2" | lolcat
echo -e "\033[33;7mDo not interrupt or close the terminal window till script finishes execution!!!\n\033[0m"

if [ "$disksize" -le 274877906944 ]; then
    echo -e ${grn}"ArchWSL2's VHD has a default maximum size of 256GB. Disk space errors which occur if size exceeds 256GB can be fixed by expanding the VHD. Would you like to resize your VHD? More information on this process is available at \033[36mhttps://docs.microsoft.com/en-us/windows/wsl/vhd-size\033[32m."${txtrst} | fold -sw $width
    select yn in "Yes" "No"; do
        case $yn in
            Yes)
                echo " "
                while read -p ${mgn}"Path to virtual disk (e.g. C:\Users\silesh\wsl\ext4.vhdx) : "${txtrst} -r vhdpath; do
                    if [ "x$vhdpath" = "x" ]; then
                        echo -e ${red}"Path cannot be blank."${txtrst}
                        echo -en "\033[1A\033[1A\033[2K"
                        vhdpath=""
                    else
                        wsl_path=$(wslpath -a $vhdpath)
                        if [ ! -f $wsl_path ]; then
                            echo -e ${red}"Disk does not exist.  "${txtrst}
                            echo -en "\033[1A\033[1A\033[2K"
                            vhdpath=""
                        else
                            echo "select vdisk file=\"$vhdpath\"" | sudo tee -a ~/vhdresize.txt >/dev/null 2>&1
                            break
                        fi
                    fi
                done
                while read -p ${mgn}"Size of virtual disk in MegaBytes(e.g. 512000 for 512GB) : "${txtrst} vhdsize; do
                    if [[ $vhdsize =~ ^-?[0-9]+$ ]]; then
                        if [ "$vhdsize" -le 256000 ]; then
                            echo -e ${red}"Disk size should be greater than 256000 MegaBytes."${txtrst}
                            echo -en "\033[1A\033[1A\033[2K"
                            vhdsize=0
                        else
                            echo -en "\033[1B\033[1A\033[2K"
                            echo "expand vdisk maximum=$vhdsize" | sudo tee -a ~/vhdresize.txt >/dev/null 2>&1
                            echo " "
                            printf "%s" "$(<~/vhdresize.txt)"
                            echo " "
                            echo -e ${grn}"\nReview the information displayed above and confirm to proceed."${txtrst}
                            echo -e ${red}"Edit only your input if you want to make changes!!!"${txtrst}
                            select yn in "Proceed" "Edit"; do
                                case $yn in
                                    Proceed)
                                        break
                                        ;;
                                    Edit)
                                        "${EDITOR:-nano}" ~/vhdresize.txt
                                        break
                                        ;;
                                esac
                            done
                            echo "@echo off" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                            echo "wsl --shutdown" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                            echo "diskpart /s C:\Users\Public\vhdresize.txt" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                            if env | grep "WT_SESSION" >/dev/null 2>&1; then
                                echo "wt.exe -w 0 nt wsl.exe -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                            else
                                echo "cmd /c start \"$WSL_DISTRO_NAME\" wsl.exe --cd ~ -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                            fi
                            cp ~/vhdresize.txt /mnt/c/Users/Public
                            cp ~/shutdown.cmd /mnt/c/Users/Public
                            break
                        fi
                    else
                        echo -e ${red}"Disk size cannot be blank and has to be numeric.  "${txtrst}
                        echo -en "\033[1A\033[1A\033[2K"
                    fi
                done

                secs=3
                printf ${ylw}"\nPlease grant diskpart elevated permissions when requested. ArchWSL2 will restart after disk resize.\n"${txtrst}
                printf ${red}"Warning!!! Any open wsl distros will be shutdown.\n\n"${txtrst}
                while [ $secs -gt 0 ]; do
                    printf "\r\033[KShutting down in %.d seconds. " $((secs--))
                    sleep 1
                done

                powershell.exe -command "Start-Process -Verb Open -FilePath 'shutdown.cmd' -WorkingDirectory 'C:\Users\Public' -WindowStyle Hidden"
                exec sleep 0
                ;;
            No)
                break
                ;;
        esac
    done
fi

echo -e ${grn}"Initializing and populating keyring..."${txtrst}
pacman-key --init >/dev/null 2>&1
pacman-key --populate >/dev/null 2>&1
pacman -Sy archlinux-keyring --noconfirm >/dev/null 2>&1
setcap cap_net_raw+p /usr/sbin/ping
sed -i '/PS1/d' /etc/skel/.bashrc
echo "PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '" | tee -a /etc/skel/.bashrc >/dev/null 2>&1
echo 'export BROWSER="wslview"' | tee -a /etc/skel/.bashrc >/dev/null 2>&1

echo -e ${grn}"Do you want to create a new user?"${txtrst}
select yn in "Yes" "No"; do
    case $yn in
        Yes)
            echo " "
            while read -p "Please enter the username you wish to create : " username; do
                if [ "x$username" = "x" ]; then
                    echo -e ${red}" Blank username entered. Try again!!!"${txtrst}
                    echo -en "\033[1A\033[1A\033[2K"
                    username=""
                elif grep -q "$username" /etc/passwd; then
                    echo -e ${red}"Username already exists. Try again!!!"${txtrst}
                    echo -en "\033[1A\033[1A\033[2K"
                    username=""
                else
                    useradd -m -g users -G wheel -s /bin/bash "$username"
                    echo -en "\033[1B\033[1A\033[2K"
                    passwd $username
                    sed -i "/\[user\]/a default = $username" /etc/wsl.conf >/dev/null
                    echo "@echo off" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                    echo "wsl.exe --terminate $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                    if env | grep "WT_SESSION" >/dev/null 2>&1; then
                        echo "wt.exe -w 0 nt wsl.exe -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                    else
                        echo "cmd /c start \"$WSL_DISTRO_NAME\" wsl.exe --cd ~ -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                    fi
                    echo "del C:\Users\Public\shutdown.cmd" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
                    cp ~/shutdown.cmd /mnt/c/Users/Public

                    if echo $(wsl.exe --version | tr -d '\0' | sed -n 1p | cut -f3 -d " " | cut -f1 -d ".") >0 || echo $(wsl.exe --version | tr -d '\0' | sed -n 1p | cut -f3 -d " " | cut -f2 -d ".") >0 || (($(echo $(wsl.exe --version | tr -d '\0' | sed -n 1p | cut -f3 -d " " | cut -f2-3 -d ".") '>' 67.5 | bc))); then
                        commandline="systemd=true"
                        echo "$commandline" >>/etc/wsl.conf
                    else
                        commandline="command = \"/usr/bin/env -i /usr/bin/unshare --fork --mount --propagation shared --mount-proc --pid -- sh -c 'mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc; [ -x /usr/lib/systemd/systemd ] && exec /usr/lib/systemd/systemd --unit=multi-user.target || exec /lib/systemd/systemd --unit=multi-user.target'\""
                        echo "$commandline" >>/etc/wsl.conf
                        wget https://raw.githubusercontent.com/diddledani/one-script-wsl2-systemd/main/src/sudoers -O /etc/sudoers.d/wsl2-systemd
                        sed -i 's/%sudo/%wheel/g' /etc/sudoers.d/wsl2-systemd
                        wget https://raw.githubusercontent.com/diddledani/one-script-wsl2-systemd/4dc64fba72251f1d9804ec64718bb005e6b27b62/src/00-wsl2-systemd.sh -P /etc/profile.d/
                        sed -i '/\\nSystemd/d' /etc/profile.d/00-wsl2-systemd.sh
                    fi

                    secs=3
                    printf ${ylw}"\nTo set the new user as the default user, ArchWSL2 will shutdown and restart!!!\n\n"${txtrst}
                    while [ $secs -gt 0 ]; do
                        printf "\r\033[KShutting down in %.d seconds. " $((secs--))
                        sleep 1
                    done

                    rm ~/.bash_profile
                    powershell.exe -command "Start-Process -Verb Open -FilePath 'shutdown.cmd' -WorkingDirectory 'C:\Users\Public' -WindowStyle Hidden"
                    exec sleep 0
                fi
            done
            ;;
        No)
            clear
            rm ~/.bash_profile
            break
            ;;
    esac
done

if echo $(wsl.exe --version | tr -d '\0' | sed -n 1p | cut -f3 -d " " | cut -f1 -d ".") >0 || echo $(wsl.exe --version | tr -d '\0' | sed -n 1p | cut -f3 -d " " | cut -f2 -d ".") >0 || (($(echo $(wsl.exe --version | tr -d '\0' | sed -n 1p | cut -f3 -d " " | cut -f2-3 -d ".") '>' 67.5 | bc))); then
    commandline="systemd=true"
    echo "$commandline" >>/etc/wsl.conf
else
    commandline="command = \"/usr/bin/env -i /usr/bin/unshare --fork --mount --propagation shared --mount-proc --pid -- sh -c 'mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc; [ -x /usr/lib/systemd/systemd ] && exec /usr/lib/systemd/systemd --unit=multi-user.target || exec /lib/systemd/systemd --unit=multi-user.target'\""
    echo "$commandline" >>/etc/wsl.conf
    wget https://raw.githubusercontent.com/diddledani/one-script-wsl2-systemd/main/src/sudoers -O /etc/sudoers.d/wsl2-systemd
    sed -i 's/%sudo/%wheel/g' /etc/sudoers.d/wsl2-systemd
    wget https://raw.githubusercontent.com/diddledani/one-script-wsl2-systemd/4dc64fba72251f1d9804ec64718bb005e6b27b62/src/00-wsl2-systemd.sh -P /etc/profile.d/
    sed -i '/\\nSystemd/d' /etc/profile.d/00-wsl2-systemd.sh
fi

echo "@echo off" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
echo "wsl.exe --terminate $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
if env | grep "WT_SESSION" >/dev/null 2>&1; then
    echo "wt.exe -w 0 nt wsl.exe -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
else
    echo "cmd /c start \"$WSL_DISTRO_NAME\" wsl.exe --cd ~ -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
fi
echo "del C:\Users\Public\shutdown.cmd" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
cp ~/shutdown.cmd /mnt/c/Users/Public

secs=3
printf ${ylw}"\nArchWSL2 will shutdown and restart to setup systemd!!!\n\n"${txtrst}
while [ $secs -gt 0 ]; do
    printf "\r\033[KShutting down in %.d seconds. " $((secs--))
    sleep 1
done

rm ~/.bash_profile
powershell.exe -command "Start-Process -Verb Open -FilePath 'shutdown.cmd' -WorkingDirectory 'C:\Users\Public' -WindowStyle Hidden"
exec sleep 0
