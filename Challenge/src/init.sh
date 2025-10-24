#!/bin/bash
set -euo pipefail
set -x

# 確保家目錄與權限
mkdir -p /home/player
chown -R player:player /home/player
chmod -R 755 /home/player

# 0_Welcome：把 welcome.sh 接到 .bashrc
if [ -f /root/src/0_Welcome/welcome.sh ]; then
	mv /root/src/0_Welcome/welcome.sh /home/player/.bashrc_append
	[ -f /home/player/.bashrc ] || touch /home/player/.bashrc
	if ! grep -Fq ". /home/player/.bashrc_append" /home/player/.bashrc; then
		echo -e "\n. /home/player/.bashrc_append" >>/home/player/.bashrc
	fi
	chown player:player /home/player/.bashrc /home/player/.bashrc_append
fi

# 1_LsCat：只複製 .jet2Holiday 與 FLAG{r_U_sUr3_th1 到家目錄
if [ -d /root/src/1_LsCat ]; then
	# 檔名含特殊字元時加引號較安全
	if [ -f "/root/src/1_LsCat/.jet2Holiday" ]; then
		cp -a "/root/src/1_LsCat/.jet2Holiday" /home/player/
	fi
	if [ -f "/root/src/1_LsCat/FLAG{r_U_sUr3_th1" ]; then
		cp -a "/root/src/1_LsCat/FLAG{r_U_sUr3_th1" /home/player/
	fi
	chown -R player:player /home/player/.jet2Holiday || true
	chown -R player:player "/home/player/FLAG{r_U_sUr3_th1" || true
fi

# 2_findTheFile：以 player 身份執行 findSetup.sh
if [ -f /root/src/2_findTheFile/findSetup.sh ]; then
	mv /root/src/2_findTheFile/findSetup.sh /home/player/findSetup.sh
	chmod +x /home/player/findSetup.sh
	runuser -u player -- /bin/bash -lc "cd /home/player && ./findSetup.sh"
	rm -f /home/player/findSetup.sh
fi

# 3_grep：兼容 gerpSetup.sh / grepSetup.sh
if [ -f /root/src/3_grep/gerpSetup.sh ]; then
	mv /root/src/3_grep/gerpSetup.sh /home/player/grepSetup.sh
	chmod +x /home/player/grepSetup.sh
	runuser -u player -- /bin/bash -lc "cd /home/player && ./grepSetup.sh"
	rm -f /home/player/grepSetup.sh
elif [ -f /root/src/3_grep/grepSetup.sh ]; then
	mv /root/src/3_grep/grepSetup.sh /home/player/grepSetup.sh
	chmod +x /home/player/grepSetup.sh
	runuser -u player -- /bin/bash -lc "cd /home/player && ./grepSetup.sh"
	rm -f /home/player/grepSetup.sh
fi

# 4_cpMvFile：
#   - 僅將 check.cpp 編譯為 checkflag，並刪除 check.cpp
#   - 另外建立 ~/temple，複製其餘內容（排除 check.cpp 與來源舊的 checkflag）
if [ -d /root/src/4_cpMvFile ]; then
	mkdir -p /home/player/temple

	# 編譯 check.cpp（若存在）
	if [ -f /root/src/4_cpMvFile/check.cpp ]; then
		# 先把源檔複製到暫存處再編譯輸出到 temple
		cp /root/src/4_cpMvFile/check.cpp /home/player/check.cpp
		g++ -std=c++17 -O2 -o /home/player/temple/checkflag /home/player/check.cpp
		rm -f /home/player/check.cpp
	fi

	# 複製其餘內容到 temple：排除 check.cpp 與（如果存在）原本的 checkflag
	shopt -s dotglob nullglob
	for item in /root/src/4_cpMvFile/*; do
		base="$(basename "$item")"
		if [ "$base" = "check.cpp" ] || [ "$base" = "checkflag" ]; then
			continue
		fi
		cp -a "$item" /home/player/temple/
	done
	shopt -u dotglob nullglob

	chown -R player:player /home/player/temple
fi

# 5_viRemoveX：搬到 cave；copy_dirtyBook.* → cave/dirtyBook；check.cpp 編譯
mkdir -p /home/player/cave
if [ -f /root/src/5_viRemoveX/check.cpp ]; then
	cp /root/src/5_viRemoveX/check.cpp /home/player/cave/check.cpp
fi
if [ -f /root/src/5_viRemoveX/copy_dirtyBook.txt ]; then
	cp /root/src/5_viRemoveX/copy_dirtyBook.txt /home/player/cave/dirtyBook.txt
elif [ -f /root/src/5_viRemoveX/copy_dirtyBook.cpp ]; then
	cp /root/src/5_viRemoveX/copy_dirtyBook.cpp /home/player/cave/dirtyBook
fi
if [ -f /home/player/cave/check.cpp ]; then
	g++ -std=c++17 -O2 -o /home/player/cave/checkflag /home/player/cave/check.cpp
	rm -f /home/player/cave/check.cpp
fi
chown -R player:player /home/player/cave

# 清理原始資源避免洩露
rm -rf /root/src || true

# 最終權限
chown -R player:player /home/player
chmod -R 755 /home/player

echo "[init] done."
