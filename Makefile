OUT_ZIP=ManjaroWSL.zip
LNCR_EXE=Manjaro.exe

DLR=curl
DLR_FLAGS=-L
LNCR_ZIP_URL=https://github.com/yuk7/wsldl/releases/download/22020900/icons.zip
LNCR_ZIP_EXE=Manjaro.exe

all: $(OUT_ZIP)

zip: $(OUT_ZIP)
$(OUT_ZIP): ziproot
	@echo -e '\e[1;31mBuilding $(OUT_ZIP)\e[m'
	cd ziproot; zip ../$(OUT_ZIP) *

ziproot: Launcher.exe rootfs.tar.gz
	@echo -e '\e[1;31mBuilding ziproot...\e[m'
	mkdir ziproot
	cp Launcher.exe ziproot/${LNCR_EXE}
	cp rootfs.tar.gz ziproot/

exe: Launcher.exe
Launcher.exe: icons.zip
	@echo -e '\e[1;31mExtracting Launcher.exe...\e[m'
	unzip icons.zip $(LNCR_ZIP_EXE)
	mv $(LNCR_ZIP_EXE) Launcher.exe

icons.zip:
	@echo -e '\e[1;31mDownloading icons.zip...\e[m'
	$(DLR) $(DLR_FLAGS) $(LNCR_ZIP_URL) -o icons.zip

rootfs.tar.gz: rootfs
	@echo -e '\e[1;31mBuilding rootfs.tar.gz...\e[m'
	cd rootfs; sudo bsdtar -zcpf ../rootfs.tar.gz `sudo ls`
	sudo chown `id -un` rootfs.tar.gz

rootfs: base.tar
	@echo -e '\e[1;31mBuilding rootfs...\e[m'
	mkdir rootfs
	sudo bsdtar -zxpf base.tar -C rootfs
	@echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee rootfs/etc/resolv.conf > /dev/null
	sudo cp -f setcap-iputils.hook rootfs/etc/pacman.d/hooks/50-setcap-iputils.hook
	sudo cp bash_profile rootfs/root/.bash_profile
	sudo setcap cap_net_raw+p /usr/sbin/ping
	sudo chmod +x rootfs

base.tar:
	@echo -e '\e[1;31mExporting base.tar using docker...\e[m'
	docker run --net=host --name manjarowsl manjarolinux/base:latest /bin/bash -c "pacman-mirrors --fasttrack 5; pacman --noconfirm --needed -Sy awk; pacman-key --init; pacman-key --populate; sed -ibak -e 's/#Color/Color/g' -e 's/CheckSpace/#CheckSpace/g' /etc/pacman.conf; pacman --noconfirm -Syyu; pacman-mirrors --country Australia,Global,Germany,Sweden,United_States --api --set-branch testing; pacman-mirrors --fasttrack 5; pacman --noconfirm -Syyuu; pacman --noconfirm -Rdd dbus; pacman --noconfirm --needed -Sy aria2 aspell base-devel ccache dbus-x11 dconf git grep hspell hunspell inetutils iputils iproute2 keychain libvoikko nano nuspell openssh procps sudo vi vim wget; touch /etc/wsl.conf; echo '[automount]' | tee -a /etc/wsl.conf > /dev/null; echo >> /etc/wsl.conf; echo '[network]' | tee -a /etc/wsl.conf > /dev/null; echo >> /etc/wsl.conf; echo '[interop]' | tee -a /etc/wsl.conf > /dev/null; echo >> /etc/wsl.conf; echo '[user]' | tee -a /etc/wsl.conf > /dev/null; echo >> /etc/wsl.conf; echo '#The Boot setting is only available on Windows 11' | tee -a /etc/wsl.conf > /dev/null; echo '[boot]' | tee -a /etc/wsl.conf > /dev/null; mkdir -p /etc/pacman.d/hooks; echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel; rm /var/lib/dbus/machine-id; dbus-uuidgen --ensure=/etc/machine-id; dbus-uuidgen --ensure; yes | LC_ALL=en_US.UTF-8 pacman -Scc; userdel builder; rm -rf /builder; sed -i '/builder ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers"
	docker export --output=base.tar manjarowsl
	docker rm -f manjarowsl

clean:
	@echo -e '\e[1;31mCleaning files...\e[m'
	-rm ${OUT_ZIP}
	-rm -r ziproot
	-rm Launcher.exe
	-rm icons.zip
	-rm rootfs.tar.gz
	-sudo rm -r rootfs
	-rm base.tar
	-docker rmi manjarolinux/base:latest -f
