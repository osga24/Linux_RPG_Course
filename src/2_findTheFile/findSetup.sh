#!/usr/bin/env bash
# random_dirs_with_flag.sh
# 產生隨機多層目錄結構，並在隨機一層放 flag.txt
# Usage:
#   ./random_dirs_with_flag.sh -b ./sample_root -d 8 -w 4 -n 200 -f flag.txt -c "FLAG{example}" -s 42
#
# Options:
#   -b BASE_DIR    基底資料夾 (預設 ./random_root)
#   -d MAX_DEPTH   最大深度 (預設 6)
#   -w MAX_WIDTH   (unused strict) 每層最多分支數提示 (預設 4)
#   -n NUM_DIRS    要建立的目錄數量目標 (預設 100)
#   -f FLAG_NAME   flag 檔名 (預設 flag.txt)
#   -c FLAG_CONTENT flag 內容 (預設 隨機字串)
#   -s SEED        固定隨機種子（方便重現）(預設 空 -> 真隨機)
#   -h             顯示說明

set -euo pipefail

BASE_DIR="./storehouse"
MAX_DEPTH=6
MAX_WIDTH=4
NUM_DIRS=100
FLAG_NAME="flag.txt"
FLAG_CONTENT="FLAG{noo!You!F1ndm3oAo}"
SEED=""
# internal for seeded RNG
_seed_counter=1

# Portable random 32-bit int:
get_random_int() {
	# If SEED is provided -> produce deterministic sequence via awk (srand + rand)
	if [ -n "${SEED:-}" ]; then
		# use and increment counter to change sequence each call
		local s="$SEED"
		local c="$_seed_counter"
		_seed_counter=$((_seed_counter + 1))
		# produce a large int
		awk -v s="$s" -v c="$c" 'BEGIN{srand(s+c); printf("%d\n", int(rand()*2147483647))}'
		return
	fi

	# Prefer openssl if available
	if command -v openssl >/dev/null 2>&1; then
		# openssl rand -hex 4 -> 8 hex chars
		hex=$(openssl rand -hex 4)
		printf "%d\n" "$((0x$hex))"
		return
	fi

	# fallback: od or hexdump from /dev/urandom
	if command -v od >/dev/null 2>&1; then
		od -An -N4 -tu4 /dev/urandom | tr -d ' \t\n'
		return
	fi

	if command -v hexdump >/dev/null 2>&1; then
		hexdump -n 4 -e '4/1 "%02x"' /dev/urandom | awk '{ printf "%d\n", strtonum("0x"$0) }'
		return
	fi

	# last fallback: bash $RANDOM combined
	echo $(((RANDOM << 15) ^ RANDOM))
}

# rand_range low high -> integer in [low,high]
rand_range() {
	local low=$1 high=$2
	if [ "$low" -gt "$high" ]; then
		local tmp=$low
		low=$high
		high=$tmp
	fi
	local r
	r=$(get_random_int)
	# handle negative or large by modulo
	local span=$((high - low + 1))
	# use awk to ensure big-int mod portable
	awk -v r="$r" -v span="$span" -v low="$low" 'BEGIN{ if (span<=0) {print low; exit} printf("%d\n", ( (r%span + span) % span ) + low)}'
}

# generate a random directory name (a-z0-9), safe on macOS (avoid tr illegal byte seq)
rand_name() {
	local len
	len=$(rand_range 3 10)

	# prefer openssl -> base64 -> /dev/urandom + od -> fallback timestamp+RANDOM
	if command -v openssl >/dev/null 2>&1; then
		# base64 then filter ascii letters+digits; LC_ALL=C to be safe
		LC_ALL=C openssl rand -base64 48 | tr -dc 'a-z0-9' | head -c "$len"
		return
	fi

	if command -v base64 >/dev/null 2>&1; then
		# convert raw bytes to base64 then filter; LC_ALL=C to avoid locale issues
		LC_ALL=C base64 </dev/urandom 2>/dev/null | tr -dc 'a-z0-9' | head -c "$len"
		return
	fi

	if command -v od >/dev/null 2>&1; then
		# use od to produce hex then map to ascii-safe characters
		od -An -N16 -tx1 /dev/urandom | tr -d ' \t\n' | fold -w2 | awk -v len="$len" '{
      for(i=1;i<=NF;i++){
        v=strtonum("0x"$i);
        # map to [0-35] then to char
        m = v % 36;
        if (m < 10) printf "%d", m;
        else printf "%c", 97 + (m-10);
      }
    }' | head -c "$len"
		return
	fi

	# last fallback
	echo "$(date +%s%N)$RANDOM" | tr -dc 'a-z0-9' | head -c "$len"
}

print_usage() {
	cat <<'USG'
Usage: random_dirs_with_flag.sh [-b BASE_DIR] [-d MAX_DEPTH] [-w MAX_WIDTH] [-n NUM_DIRS] [-f FLAG_NAME] [-c FLAG_CONTENT] [-s SEED]

Example:
  ./random_dirs_with_flag.sh -b ./sample -d 8 -w 5 -n 500 -f flag.txt -c "FLAG{you_found_it}" -s 42
USG
}

# parse args
while getopts "b:d:w:n:f:c:s:h" opt; do
	case "$opt" in
	b) BASE_DIR="$OPTARG" ;;
	d) MAX_DEPTH="$OPTARG" ;;
	w) MAX_WIDTH="$OPTARG" ;;
	n) NUM_DIRS="$OPTARG" ;;
	f) FLAG_NAME="$OPTARG" ;;
	c) FLAG_CONTENT="$OPTARG" ;;
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

# sanity checks
if ! [[ "$NUM_DIRS" =~ ^[0-9]+$ ]]; then
	echo "NUM_DIRS must be a non-negative integer" >&2
	exit 1
fi
if ! [[ "$MAX_DEPTH" =~ ^[0-9]+$ ]] || [ "$MAX_DEPTH" -le 0 ]; then
	echo "MAX_DEPTH must be a positive integer" >&2
	exit 1
fi

# prepare base dir
mkdir -p -- "$BASE_DIR"
if [ ! -d "$BASE_DIR" ]; then
	echo "Error: cannot create/access base dir $BASE_DIR" >&2
	exit 1
fi

# generate a random flag content if not provided
if [ -z "$FLAG_CONTENT" ]; then
	# use openssl if available, else base64, else timestamp
	if command -v openssl >/dev/null 2>&1; then
		FLAG_CONTENT="$(LC_ALL=C openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 24)"
	elif command -v base64 >/dev/null 2>&1; then
		FLAG_CONTENT="$(LC_ALL=C base64 </dev/urandom 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 24)"
	else
		FLAG_CONTENT="FLAG_$(date +%s%N)"
	fi
fi

echo "Base dir: $BASE_DIR"
echo "Target num dirs: $NUM_DIRS, max depth: $MAX_DEPTH"
[ -n "$SEED" ] && echo "Using seed: $SEED (deterministic)"

created_paths=()
count=0

# create directories loop
while [ "$count" -lt "$NUM_DIRS" ]; do
	depth=$(rand_range 1 "$MAX_DEPTH")
	path="$BASE_DIR"
	for ((i = 1; i <= depth; i++)); do
		name=$(rand_name)
		# ensure name non-empty
		if [ -z "$name" ]; then
			name="d$(rand_range 0 99999)"
		fi
		path="$path/$name"
	done

	# create directory (mkdir -p idempotent)
	if mkdir -p -- "$path"; then
		# avoid duplicates: only append if not equal last element
		# (we don't want a huge in-array duplicate check for performance)
		created_paths+=("$path")
		count=$((count + 1))
	fi
done

# choose random index among created_paths
if [ "${#created_paths[@]}" -eq 0 ]; then
	echo "No directories were created. Exiting." >&2
	exit 1
fi
idx=$(rand_range 0 $((${#created_paths[@]} - 1)))
selected="${created_paths[$idx]}"

# write the flag file (use printf to avoid locale issues)
flagpath="$selected/$FLAG_NAME"
printf '%s\n' "$FLAG_CONTENT" >"$flagpath"
chmod 644 "$flagpath"

echo "Created $count directories."
echo "Flag placed at: $flagpath"
echo "Flag content (preview): $(printf '%.80s' "$FLAG_CONTENT")"
