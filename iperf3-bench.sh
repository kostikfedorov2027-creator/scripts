#!/usr/bin/env bash
# iperf3-bench.sh — суммарная информация по каждому тесту + цветовая индикация скорости
# Использование: ./iperf3-bench.sh [--duration N] [--streams N] [--port N] [--no-color]

set -u

DURATION=10
STREAMS=4
PORT=5201
TIMEOUT=15
USE_COLOR=1

SERVERS=(
  de1.svo-vpn.ru de2.svo-vpn.ru de3.svo-vpn.ru
  pl1.svo-vpn.ru pl2.svo-vpn.ru pl3.svo-vpn.ru pl5.svo-vpn.ru
  fi1.svo-vpn.ru nl3.svo-vpn.ru sg1.svo-vpn.ru
  ro2.svo-vpn.ru ca1.svo-vpn.ru fr1.svo-vpn.ru
  no1.svo-vpn.ru us1.svo-vpn.ru
)

# ---------- разбор аргументов ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --duration) DURATION="$2"; shift 2 ;;
    --streams)  STREAMS="$2";  shift 2 ;;
    --port)     PORT="$2";     shift 2 ;;
    --no-color) USE_COLOR=0;   shift ;;
    -h|--help)
      echo "Usage: $0 [--duration N] [--streams N] [--port N] [--no-color]"
      exit 0 ;;
    *) echo "Неизвестный аргумент: $1"; exit 1 ;;
  esac
done

# ---------- цвета ----------
if [[ "$USE_COLOR" -eq 1 ]] && [[ -t 1 ]]; then
  GREEN=$'\033[1;32m'
  YELLOW=$'\033[1;33m'
  RED=$'\033[1;31m'
  CYAN=$'\033[1;36m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  NC=$'\033[0m'
else
  GREEN=""; YELLOW=""; RED=""; CYAN=""; BOLD=""; DIM=""; NC=""
fi

# ---------- проверка iperf3 ----------
if ! command -v iperf3 >/dev/null 2>&1; then
  echo "Ошибка: iperf3 не найден в PATH (apt install iperf3 / brew install iperf3)."
  exit 1
fi

# ---------- форматирование скорости ----------
fmt_bits() {
  local bps="$1"
  awk -v b="$bps" 'BEGIN{
    if (b=="" || b==0) { print "n/a"; exit }
    split("bit Kbit Mbit Gbit Tbit", u, " ")
    i=1
    while (b>=1000 && i<5) { b/=1000; i++ }
    printf "%.2f %s/s", b, u[i]
  }'
}

# ---------- выбор цвета по скорости ----------
# >300 Mbit/s → GREEN | 100..299.99 → YELLOW | <100 → RED
color_by_bps() {
  local bps="${1:-0}"
  awk -v b="$bps" -v g="$GREEN" -v y="$YELLOW" -v r="$RED" -v n="$NC" 'BEGIN{
    if (b == "" || b+0 == 0) { printf "%s%s%s", r, "n/a", n; exit }
    m = b/1e6
    if (m > 300)       printf "%s%.2f Mbit/s%s", g, m, n
    else if (m >= 100) printf "%s%.2f Mbit/s%s", y, m, n
    else               printf "%s%.2f Mbit/s%s", r, m, n
  }'
}

# ---------- запуск одного теста ----------
run_test() {
  local host="$1" dir="$2"
  local reverse_flag=""
  [[ "$dir" == "recv" ]] && reverse_flag="-R"

  local json
  json=$(timeout $((DURATION + TIMEOUT)) \
    iperf3 -c "$host" -p "$PORT" -t "$DURATION" -P "$STREAMS" \
           $reverse_flag -J 2>/dev/null)

  if [[ -z "$json" ]] || ! echo "$json" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    echo "ERROR"
    return 1
  fi
  echo "$json"
}

# ---------- извлечь bps и retransmits ----------
extract_bps() {
  python3 -c "
import sys,json
d=json.loads(sys.argv[1])
print(int(d['end']['$2'].get('bits_per_second',0)))" "$1" 2>/dev/null || echo 0
}
extract_retrans() {
  python3 -c "
import sys,json
d=json.loads(sys.argv[1])
print(int(d['end'].get('sum_sent',{}).get('retransmits',0)))" "$1" 2>/dev/null || echo 0
}

# ---------- печать одной строки результата ----------
print_row() {
  local dir="$1" json="$2"
  local label field
  if [[ "$dir" == "send" ]]; then label="↑ Upload  "; field="sum_sent"
  else                             label="↓ Download"; field="sum_received"; fi

  local bps retrans
  bps=$(extract_bps "$json" "$field")
  retrans=$(extract_retrans "$json")
  printf "  %-12s %s  %s\n" "$label" "$(color_by_bps "$bps")" "${DIM}retrans=${retrans}${NC}"
}

# ---------- разделители ----------
hr() { printf '%s' "$DIM"; printf '%.0s─' {1..80}; printf '%s\n' "$NC"; }
hr2() { printf '%s' "$CYAN"; printf '%.0s═' {1..80}; printf '%s\n' "$NC"; }

# ---------- шапка ----------
printf "${BOLD}%-22s %-8s %s${NC}\n" "SERVER" "STATUS" "RESULTS"
hr

declare -a SUMMARY
ok=0; skip=0; fail=0

# ---------- основной цикл ----------
for host in "${SERVERS[@]}"; do
  # проверка доступности порта
  if ! timeout 3 bash -c "</dev/tcp/$host/$PORT" >/dev/null 2>&1; then
    printf "%-22s %s%-8s%s %s\n" "$host" "$YELLOW" "SKIP" "$NC" "порт $PORT недоступен"
    SUMMARY+=("$host|SKIP|порт недоступен|0|0")
    skip=$((skip+1))
    continue
  fi

  upload_json=$(run_test "$host" "send")
  download_json=$(run_test "$host" "recv")

  if [[ "$upload_json" == "ERROR" && "$download_json" == "ERROR" ]]; then
    printf "%-22s %s%-8s%s %s\n" "$host" "$RED" "FAIL" "$NC" "не удалось выполнить iperf3"
    SUMMARY+=("$host|FAIL|ошибка соединения|0|0")
    fail=$((fail+1))
    continue
  fi

  printf "%-22s %s%-8s%s\n" "$host" "$GREEN" "OK" "$NC"

  up_bps=0; dn_bps=0
  if [[ "$upload_json" != "ERROR" ]]; then
    print_row "send" "$upload_json"
    up_bps=$(extract_bps "$upload_json" "sum_sent")
  fi
  if [[ "$download_json" != "ERROR" ]]; then
    print_row "recv" "$download_json"
    dn_bps=$(extract_bps "$download_json" "sum_received")
  fi

  SUMMARY+=("$host|OK|-|$up_bps|$dn_bps")
  ok=$((ok+1))
done

# ---------- сводка ----------
echo
hr2
printf "${BOLD}%-22s %-8s %-22s %-22s${NC}\n" "SERVER" "STATUS" "↑ UPLOAD" "↓ DOWNLOAD"
hr2

for line in "${SUMMARY[@]}"; do
  IFS='|' read -r h st info up dn <<< "$line"

  case "$st" in
    OK)   st_col="$GREEN" ;;
    SKIP) st_col="$YELLOW" ;;
    FAIL) st_col="$RED" ;;
    *)    st_col="$NC" ;;
  esac

  if [[ "$st" == "OK" ]]; then
    printf "%-22s ${st_col}%-8s${NC} %-22s %-22s\n" \
      "$h" "$st" "$(color_by_bps "$up")" "$(color_by_bps "$dn")"
  else
    printf "%-22s ${st_col}%-8s${NC} %s\n" "$h" "$st" "$info"
  fi
done

hr2
printf "${BOLD}Всего:${NC} ${GREEN}OK=$ok${NC}  ${YELLOW}SKIP=$skip${NC}  ${RED}FAIL=$fail${NC}  ${DIM}(из ${#SERVERS[@]})${NC}\n"
printf "${DIM}Легенда: ${GREEN}>300 Mbit/s${NC} ${DIM}|${NC} ${YELLOW}100–300 Mbit/s${NC} ${DIM}|${NC} ${RED}<100 Mbit/s${NC}\n"