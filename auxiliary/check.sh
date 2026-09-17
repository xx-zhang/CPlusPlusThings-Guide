#!/usr/bin/env bash
# check.sh —— auxiliary/ 体系自检（机器强制版）
# 用法: cd auxiliary && ./check.sh
# 作用: 把 26 §4 的人工清单变成可执行检查，防止腐化（引用断链 / 字段缺失 / 计数漂移 / 实测过期 / SSOT 违规）
# SSOT 三级规则见 08 §3；本脚本是其强制层。
set -u

cd "$(dirname "$0")" || exit 1

FAIL=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ── SSOT ①：非确定性数字只允许出现在 08（随机结果不是标准值）──
PROTECTED_NUMBERS='212561|329722|226264'
SSOT_OWNER='08-记忆固化手册.md'
# ── SSOT ②：活台账的持有者与指针 ──
LEDGER_OWNER='26-骨架总图与索引.md'
LEDGER_REF='26 §1.4'

ok() { printf "  \033[32m✅\033[0m %s\n" "$1"; }
bad() {
  printf "  \033[31m❌\033[0m %s\n" "$1"
  FAIL=$((FAIL + 1))
}
info() { printf "  \033[33m·\033[0m  %s\n" "$1"; }

TOTAL=0
section() {
  TOTAL=$((TOTAL + 1))
  echo "═══ $TOTAL. $1 ═══"
}

section "交叉引用完整性（引用的文件必须存在）"
grep -ohE '`(lessons/)?[0-9]{2}-[^`]*\.md`' --include='*.md' -r . | tr -d '`' | sort -u >"$TMP/refs"
missing=0
while read -r f; do
  if [ ! -f "$f" ]; then
    bad "断链: $f"
    missing=1
  fi
done <"$TMP/refs"
if [ "$missing" -eq 0 ]; then
  ok "引用的 $(wc -l <"$TMP/refs") 个文件全部存在"
fi

section "定理字段完整性（T1-T12 须有「失效前提」与「仓库章节」）"
if ! python3 - <<'PY'
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
then FAIL=$((FAIL + 1)); fi

section "结构规则（markdownlint 结构类错误为 0）"
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

section "README 是否收录全部文档"
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

section "计数一致性（定理数声称 vs 实际）"
actual=$(grep -c '^### T[0-9]' 01-知识框架.md)
claim=$(grep -ohE '十二条派生定理|12 条定理' 01-知识框架.md README.md 2>/dev/null | wc -l)
if [ "$actual" -eq 12 ] && [ "$claim" -gt 0 ]; then
  ok "实际 $actual 条，且有「12 条」的说法（$claim 处）"
else
  bad "实际 $actual 条，声称处数 $claim（应为 12 / >0）"
fi

section "关键实测回归（EBO / 布局 / 常量折叠 / 窄化 / 交叉编译）"
cat >"$TMP/reg.cpp" <<'EOF'
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

printf 'int main(){ int b{3.9}; return b; }\n' >"$TMP/nar.cpp"
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

section "SSOT ①：非确定性数字只允许出现在 $SSOT_OWNER"
violators=$(grep -rlE "$PROTECTED_NUMBERS" --include='*.md' . 2>/dev/null | grep -v "$SSOT_OWNER" || true)
if [ -z "$violators" ]; then
  ok "受保护数字未泄漏到其它文件"
else
  for v in $violators; do bad "SSOT 违规：$v 复述了非确定性数字（应在 $SSOT_OWNER）"; done
fi

section "SSOT ②：活台账指针（00 §5 必须指向 $LEDGER_REF）"
if grep -q "$LEDGER_REF" 00-方法论自检与迁移.md 2>/dev/null; then
  ok "00 §5 含指向 $LEDGER_OWNER 的活台账指针"
else
  bad "00 §5 缺少指向 $LEDGER_REF 的指针（会出现两处口径矛盾）"
fi

section "SSOT ③：确定性实测回归 —— 去虚化（T5）"
cat >"$TMP/virt.cpp" <<'EOF'
struct Base { virtual ~Base() = default; virtual int f() const { return 1; } };
struct Derived : Base { int f() const override { return 2; } };
struct Sealed final : Base { int f() const override { return 3; } };
int call_ref(Base& b) { return b.f(); }
int call_final(Sealed& s) { return s.f(); }
EOF
if g++ -std=c++17 -O2 -S "$TMP/virt.cpp" -o "$TMP/virt.s" 2>/dev/null; then
  awk '/^_Z10call_finalR6Sealed:/,/^[[:space:]]*\.size/' "$TMP/virt.s" >"$TMP/cf.s"
  awk '/^_Z8call_refR4Base:/,/^[[:space:]]*\.size/' "$TMP/virt.s" >"$TMP/cr.s"
  if grep -qE 'movl[[:space:]]+\$3, %eax' "$TMP/cf.s" && ! grep -qE 'jmp[[:space:]]+\*' "$TMP/cf.s"; then
    ok "call_final(Sealed&) 完全去虚化（movl \$3, %eax，无间接跳转）"
  else
    bad "去虚化结论失效：call_final 汇编与 08 记录不符"
  fi
  if grep -qE 'jmp[[:space:]]+\*' "$TMP/cr.s"; then
    ok "call_ref(Base&) 仍是动态派发（间接跳转）——对照组成立"
  else
    bad "对照组异常：call_ref 也变成了静态调用"
  fi
else
  bad "去虚化回归程序编译失败"
fi

section "SSOT ③：确定性实测回归 —— 弱符号（T6）"
cat >"$TMP/w.cpp" <<'EOF'
inline int add(int a, int b) { return a + b; }
int x() { return add(1, 2); }
EOF
if g++ -std=c++17 -c "$TMP/w.cpp" -o "$TMP/w.o" 2>/dev/null; then
  if nm -C "$TMP/w.o" | grep -qE ' W add\(int, int\)'; then
    ok "inline 函数产生弱符号 W（T6 前提成立）"
  else
    bad "未检出弱符号：T6/08 的结论失效"
  fi
else
  bad "弱符号回归程序编译失败"
fi

section "一致性：27 的「设计意图」列必须挂靠 D1-D5 / 元原则（防复述塌缩）"
if ! python3 - <<'PY2'
import re, sys
rows = [l for l in open('27-能力清单与设计意图.md', encoding='utf-8').read().splitlines()
        if l.startswith('| **') and l.count('|') >= 6]
bad = []
for l in rows:
    c = [x.strip() for x in l.split('|')]
    if not re.search(r'(D[1-5]|元[123]|A5)', c[4]):
        bad.append(c[1])
if bad:
    print("  \033[31m❌\033[0m 意图列未挂靠原则: " + "; ".join(bad))
    sys.exit(1)
print(f"  \033[32m✅\033[0m {len(rows)} 行的意图均挂靠到 D/元原则")
PY2
then FAIL=$((FAIL + 1)); fi

echo
if [ "$FAIL" -eq 0 ]; then
  printf "\033[32m═══ 全部通过（%d 项检查）═══\033[0m\n" "$TOTAL"
else
  printf "\033[31m═══ %d 项检查失败 ═══\033[0m\n" "$FAIL"
  exit 1
fi
