#!/usr/bin/env bash
# random_dirs_with_flag.sh (macOS/Linux compatible)
# 1) 隨機建立多層目錄
# 2) 在每個目錄中建立若干「文章檔」（內容相同）
# 3) 僅在其中一個檔案的內文中藏入 flag（plain|comment|zwsp）
#
# 範例：
#   ./random_dirs_with_flag.sh -b ./storehouse -n 80 -d 6 -k 2 -F note.txt \
#      -c 'FLAG{example}' -x comment -s 42

set -euo pipefail

# ======================== 參數與預設 ========================
BASE_DIR="./library"
MAX_DEPTH=6
NUM_DIRS=100
FILES_PER_DIR=1
FILE_NAME="article.txt"
ARTICLE_PATH=""                                  # 若留空，用內建文章
FLAG_CONTENT="FLAG{n0_w4y_y0u_r34d_4ll_0f_th3m}" # 若留空，自動產生
HIDE_MODE="comment"                              # plain | comment | zwsp
SEED=""
_seed_counter=1

# ======================== 工具函式：隨機 =====================
get_random_int() {
	if [ -n "${SEED:-}" ]; then
		local s="$SEED" c="$_seed_counter"
		_seed_counter=$((_seed_counter + 1))
		awk -v s="$s" -v c="$c" 'BEGIN{srand(s+c); printf("%d\n", int(rand()*2147483647))}'
		return
	fi
	if command -v openssl >/dev/null 2>&1; then
		hex=$(openssl rand -hex 4)
		printf "%d\n" "$((0x$hex))"
		return
	fi
	if command -v od >/dev/null 2>&1; then
		od -An -N4 -tu4 /dev/urandom | tr -d ' \t\n'
		return
	fi
	if command -v hexdump >/dev/null 2>&1; then
		hexdump -n 4 -e '4/1 "%02x"' /dev/urandom | awk '{ printf "%d\n", strtonum("0x"$0) }'
		return
	fi
	echo $(((RANDOM << 15) ^ RANDOM))
}

rand_range() { # [low, high]
	local low=$1 high=$2
	if [ "$low" -gt "$high" ]; then
		local t=$low
		low=$high
		high=$t
	fi
	local r span=$((high - low + 1))
	r=$(get_random_int)
	awk -v r="$r" -v span="$span" -v low="$low" \
		'BEGIN{ if (span<=0){print low; exit} printf("%d\n", ((r%span+span)%span)+low) }'
}

rand_name() {
	local len
	len=$(rand_range 3 10)
	if command -v openssl >/dev/null 2>&1; then
		LC_ALL=C openssl rand -base64 48 | tr -dc 'a-z0-9' | head -c "$len"
		return
	fi
	if command -v base64 >/dev/null 2>&1; then
		LC_ALL=C base64 </dev/urandom 2>/dev/null | tr -dc 'a-z0-9' | head -c "$len"
		return
	fi
	if command -v od >/dev/null 2>&1; then
		od -An -N16 -tx1 /dev/urandom | tr -d ' \t\n' | fold -w2 | awk -v len="$len" '{
      for(i=1;i<=NF;i++){v=strtonum("0x"$i); m=v%36; if(m<10)printf "%d",m; else printf "%c",97+(m-10)}
    }' | head -c "$len"
		return
	fi
	echo "$(date +%s%N)$RANDOM" | tr -dc 'a-z0-9' | head -c "$len"
}

# ======================== 文章模板 ==========================
builtin_article() {
	cat <<'TXT'
	好 那今天呢 風光明媚風和日麗 因爲我以前在唸書的時候我常常覺得很奇怪就是我到學校然後看他們吃什麼早餐都是吃一份蛋餅配一杯奶茶 或是 一個漢堡配一杯奶茶 或是一份蘿蔔糕配一杯奶茶 每次吃完都說啊我吃飽了我心裡就想說：「這真的可以吃飽？」因爲你知道我通常早餐我都點3份可能3個 我想說這樣就能吃飽？一定是唬人的嘛我才想到說大家都是要面子的：「沒有沒有 我都帶好幾份去吃」「那是你嘛你不要臉嘛我說正常的」我就想說不行 我們一定要做個企劃 就是有一天要讓自己的胃滿足 大滿足所以今天的企劃就是 早餐吃到飽
TXT
}

load_article() {
	if [ -n "$ARTICLE_PATH" ]; then
		[ -r "$ARTICLE_PATH" ] || {
			echo "ERROR: ARTICLE_PATH 不可讀：$ARTICLE_PATH" >&2
			exit 1
		}
		cat -- "$ARTICLE_PATH"
	else
		builtin_article
	fi
}

# ======================== 藏旗（無 mapfile 版） =============
inject_flag_plain() {
	cat
	printf "\n\n[FLAG] %s\n" "$FLAG_CONTENT"
}

inject_flag_comment() {
	local tmp
	tmp=$(mktemp)
	cat >"$tmp"
	local total
	total=$(wc -l <"$tmp" | tr -d ' ')
	[ -z "$total" ] && total=0
	local pos
	pos=$(rand_range 0 "$total") # 0 表最前面
	local line="<!-- secret note: $FLAG_CONTENT -->"
	if [ "$pos" -le 0 ]; then
		{
			printf "%s\n" "$line"
			cat "$tmp"
		}
	else
		# 在第 pos 行之前插入（兼容 BSD sed）
		sed "${pos}i\\
$line
" "$tmp"
	fi
	rm -f "$tmp"
}

inject_flag_zwsp() {
	local ZWSP
	ZWSP=$(printf '\xE2\x80\x8B')
	local hidden flag="$FLAG_CONTENT"
	hidden=$(printf "%s" "$flag" | awk -v z="$ZWSP" 'BEGIN{ORS=""} {for(i=1;i<=length($0);i++) printf("%s%s", substr($0,i,1), z)} END{print ""}')
	cat
	printf "\n\nnote:%s\n" "$hidden"
}

inject_flag_into_article() {
	case "$HIDE_MODE" in
	plain) inject_flag_plain ;;
	comment) inject_flag_comment ;;
	zwsp) inject_flag_zwsp ;;
	*)
		echo "未知 HIDE_MODE: $HIDE_MODE（可用：plain|comment|zwsp）" >&2
		exit 1
		;;
	esac
}

# ======================== 使用說明 ==========================
print_usage() {
	cat <<'USG'
Usage:
  random_dirs_with_flag_no_manifest.sh [-b BASE_DIR] [-d MAX_DEPTH] [-n NUM_DIRS]
                                      [-k FILES_PER_DIR] [-F FILE_NAME]
                                      [-A ARTICLE_PATH] [-c FLAG_CONTENT]
                                      [-x HIDE_MODE] [-s SEED]
USG
}

# ======================== 解析參數 ==========================
while getopts "b:d:n:k:F:A:c:x:s:h" opt; do
	case "$opt" in
	b) BASE_DIR="$OPTARG" ;;
	d) MAX_DEPTH="$OPTARG" ;;
	n) NUM_DIRS="$OPTARG" ;;
	k) FILES_PER_DIR="$OPTARG" ;;
	F) FILE_NAME="$OPTARG" ;;
	A) ARTICLE_PATH="$OPTARG" ;;
	c) FLAG_CONTENT="$OPTARG" ;;
	x) HIDE_MODE="$OPTARG" ;;
	s) SEED="$OPTARG" ;;
	h)
		print_usage
		exit 0
		;;
	*)
		print_usage
		exit 1
		;;
	esac
done

# ======================== 檢查與準備 ========================
[[ "$NUM_DIRS" =~ ^[0-9]+$ ]] || {
	echo "NUM_DIRS must be integer" >&2
	exit 1
}
[[ "$MAX_DEPTH" =~ ^[0-9]+$ ]] && [ "$MAX_DEPTH" -gt 0 ] || {
	echo "MAX_DEPTH must be >0" >&2
	exit 1
}
[[ "$FILES_PER_DIR" =~ ^[0-9]+$ ]] && [ "$FILES_PER_DIR" -ge 1 ] || {
	echo "FILES_PER_DIR must be >=1" >&2
	exit 1
}

mkdir -p -- "$BASE_DIR"
[ -d "$BASE_DIR" ] || {
	echo "Cannot access BASE_DIR: $BASE_DIR" >&2
	exit 1
}

if [ -z "$FLAG_CONTENT" ]; then
	if command -v openssl >/dev/null 2>&1; then
		FLAG_CONTENT="$(LC_ALL=C openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 24)"
	elif command -v base64 >/dev/null 2>&1; then
		FLAG_CONTENT="$(LC_ALL=C base64 </dev/urandom 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 24)"
	else
		FLAG_CONTENT="FLAG_$(date +%s%N)"
	fi
fi

ARTICLE_TEXT="$(load_article)"

echo "Base dir: $BASE_DIR"
echo "Target dirs: $NUM_DIRS, max depth: $MAX_DEPTH, files/dir: $FILES_PER_DIR"
[ -n "$SEED" ] && echo "Using seed: $SEED"
echo "Hide mode: $HIDE_MODE"
echo "File name: $FILE_NAME"

created_paths=()
count=0

# ======================== 建立目錄 ==========================
while [ "$count" -lt "$NUM_DIRS" ]; do
	depth=$(rand_range 1 "$MAX_DEPTH")
	path="$BASE_DIR"
	for ((i = 1; i <= depth; i++)); do
		name=$(rand_name)
		[ -n "$name" ] || name="d$(rand_range 0 99999)"
		path="$path/$name"
	done
	mkdir -p -- "$path" && {
		created_paths+=("$path")
		count=$((count + 1))
	}
done

[ "${#created_paths[@]}" -gt 0 ] || {
	echo "No directories created"
	exit 1
}

# ======================== 挑一個檔案藏 flag =================
tgt_dir_idx=$(rand_range 0 $((${#created_paths[@]} - 1)))
tgt_file_idx=$(rand_range 1 "$FILES_PER_DIR") # 1..FILES_PER_DIR

flag_abs_path=""

# ======================== 寫入檔案 ==========================
dir_no=0
for dir in "${created_paths[@]}"; do
	dir_no=$((dir_no + 1))
	for ((j = 1; j <= FILES_PER_DIR; j++)); do
		fpath="$dir/$j-$FILE_NAME"
		if [ "$dir_no" -eq $((tgt_dir_idx + 1)) ] && [ "$j" -eq "$tgt_file_idx" ]; then
			# 這一份要藏 flag
			printf "%s\n" "$ARTICLE_TEXT" | inject_flag_into_article >"$fpath"
			# 取得絕對路徑（POSIX portable): use realpath if available, else python fallback
			if command -v realpath >/dev/null 2>&1; then
				flag_abs_path=$(realpath "$fpath")
			else
				flag_abs_path=$(python3 -c "import os,sys; print(os.path.abspath(sys.argv[1]))" "$fpath")
			fi
		else
			printf "%s\n" "$ARTICLE_TEXT" >"$fpath"
		fi
		chmod 644 "$fpath" 2>/dev/null || true
	done
done

echo "Created $count directories, total files: $((count * FILES_PER_DIR))."
if [ -n "$flag_abs_path" ]; then
	echo "Flag is hidden in ONE file (no manifest written)."
	echo "Flag absolute path:"
	printf "%s\n" "$flag_abs_path"
else
	echo "ERROR: flag path not recorded." >&2
	exit 1
fi

# 提示搜尋方式（不會暴露 flag 內容）
echo "If you want to inspect files: grep -R 'FLAG{' -n -- \"$BASE_DIR\" 2>/dev/null || less <that file>"
