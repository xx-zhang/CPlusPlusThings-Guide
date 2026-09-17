#!/usr/bin/env bash
# check.sh —— auxiliary/ 体系自检（机器强制版）
# 用法: cd auxiliary && ./check.sh
# 作用: 把 26 §4 的人工清单变成可执行检查，防止未来腐化（引用断链 / 字段缺失 / 计数漂移 / 实测过期）
set -u

cd "$(dirname "$0")" || exit 1

FAIL=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ok()   { printf "  \033[32m✅\033[0m %s\n" "$1"; }
bad()  { printf "  \033[31m❌\033[0m %s\n" "$1"; FAIL=$((FAIL + 1)); }
info() { printf "  \033[33m·\033[0m  %s\n" "$1"; }

echo "═══ 1. 交叉引用完整性（引用的文件必须存在） ═══"
grep -ohE '`(lessons/)?[0-9]{2}-[^`]*\.md`' --include='*.md' -r . | tr -d '`' | sort -u > "$TMP/refs"
missing=0
while read -r f; do
  if [ ! -f "$f" ]; then
    bad "断链: $f"
    missing=1
  fi
done < "$TMP/refs"
if [ "$missing" -eq 0 ]; then
  ok "引用的 $(wc -l < "$TMP/refs") 个文件全部存在"
fi

echo "═══ 2. 定理字段完整性（T1-T12 须有「失效前提」与「仓库章节」） ═══"
if python3 - <<'PY'
import re, sys
s = open('01-知识框架.md', encoding='utf-8').read()
idx = [(m.start(), m.group(1)) for m in re.finditer(r'^### (T\d+) ·', s, re.M)]
idx.append((len(s), 'END'))
bad = []
for i in range(len(idx) - 1):
    name = idx[i][1]
    sec = s[idx[i][0]:idx[i + 1][0]]
    for field in ('失效前提', '仓库章节'):
        if field not in sec:
            bad.append(f"{name} 缺「{field}」")
if bad:
    print("  \033[31m❌\033[0m " + "; ".join(bad))
    sys.exit(1)
print(f"  \033[32m✅\033[0m 检测到 {len(idx) - 1} 条定理，字段齐全")
PY
then :; else FAIL=$((FAIL + 1)); fi

echo "═══ 3. 结构规则（markdownlint 结构类错误为 0） ═══"
if command -v npx >/dev/null 2>&1; then
  n=$(npx --yes markdownlint-cli2 '**/*.md' 2>&1 | grep -cE "MD036|MD040|MD055|MD056" || true)
  if [ "$n" -eq 0 ]; then
    ok "MD036/MD040/MD055/MD056 = 0"
  else
    bad "结构类错误 $n 处"
  fi
else
  info "无 npx，跳过"
fi

echo "═══ 4. README 是否收录全部文档 ═══"
miss=""
for f in *.md lessons/*.md; do
  b=$(basename "$f")
  if [ "$b" = "README.md" ]; then continue; fi
  if ! grep -qF "$b" README.md; then miss="$miss $b"; fi
done
if [ -z "$miss" ]; then
  ok "全部文档已收录"
else
  bad "未收录:$miss"
fi

echo "═══ 5. 计数一致性（定理数声称 vs 实际） ═══"
actual=$(grep -c '^### T[0-9]' 01-知识框架.md)
claim=$(grep -ohE '十二条派生定理|12 条定理' 01-知识框架.md README.md 2>/dev/null | wc -l)
if [ "$actual" -eq 12 ] && [ "$claim" -gt 0 ]; then
  ok "实际 $actual 条，且有「12 条」的说法（$claim 处）"
else
  bad "实际 $actual 条，声称处数 $claim（应为 12 / >0）"
fi

echo "═══ 6. 关键实测回归（快速、确定性） ═══"
cat > "$TMP/reg.cpp" <<'EOF'
#include <cstdio>
struct E {}; struct EBO : E { int x; }; struct NoEBO { E e; int x; };
class A { public: char a; int b; };
class B : A { public: short a; long b; };
int f(int x) { return x + 1 > x; }
int main(){ std::printf("%zu %zu %zu %zu %d\n", sizeof(E), sizeof(EBO), sizeof(NoEBO), sizeof(B), f(1)); }
EOF
if g++ -std=c++17 -w "$TMP/reg.cpp" -o "$TMP/reg" 2>/dev/null; then
  got=$("$TMP/reg")
  want="1 4 8 24 1"
  if [ "$got" = "$want" ]; then
    ok "EBO/布局/常量折叠: $got"
  else
    bad "实测漂移！得到 [$got]，期望 [$want]"
  fi
else
  bad "回归程序编译失败"
fi

printf 'int main(){ int b{3.9}; return b; }\n' > "$TMP/nar.cpp"
if g++ -std=c++17 -fsyntax-only "$TMP/nar.cpp" 2>/dev/null; then
  bad "常量窄化未报错（T8 / 22 §3 的结论失效）"
else
  ok "常量窄化仍为硬错误（T8 前提成立）"
fi

if command -v clang++ >/dev/null 2>&1; then
  if clang++ -std=c++17 -w -fsyntax-only "$TMP/reg.cpp" 2>/dev/null; then
    ok "clang++ 交叉编译通过"
  else
    bad "clang++ 编译失败"
  fi
fi

echo
if [ "$FAIL" -eq 0 ]; then
  printf "\033[32m═══ 全部通过（6 项检查）═══\033[0m\n"
else
  printf "\033[31m═══ %d 项检查失败 ═══\033[0m\n" "$FAIL"
  exit 1
fi
