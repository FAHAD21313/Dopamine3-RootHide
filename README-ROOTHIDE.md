# Dopamine 3.0.8 — RootHide Edition

Dopamine 3.0.8 (opa334) معاد بناؤه فوق معمارية **RootHide** المخفية — أول جلبريك roothide يستهدف iOS 18.x.

## نطاق الدعم المستهدف
| الأجهزة | الإصدارات |
|---|---|
| A12/A13 (arm64e) | iOS 15.0 – 18.7.1, 26.0 – 26.0.1 (PPL) |
| arm64e A14+ | iOS 15.0 – 17.3.1 (SPTM) |
| arm64 | iOS 15.0 – 18.7.1 |

جهاز الاختبار الأساسي: iPhone 11 (A13) / iOS 18.3.2
سلسلة الاستغلال: ClearSword (kernel r/w) → momentarius (PPL bypass) → badRecovery (PAC)

## البنية (ما تغيّر عن 3.0.8)
- `libjailbreak/src/jbrand.{m,h}` — الجذر العشوائي `.jbroot-<jbrand>` (مصدر وحيد، G43)
- `libjailbreak/src/roothider/` + `jbclient_roothide.c` — محرك الإخفاء الكامل
- `jailbreakd/` يستبدل دايمون `dopamine/` (entitlements من 3.0.8)
- `dyldhook/src/roothider.{c,S}` — ترجمة `@loader_path/.jbroot` في dyld4
- `launchdhook/src/jbserver/jbdomain_roothide.c` — دومين ROOTHIDE (index 6؛ Dopamine يبقى 5)
- `systemhook/src/roothider_main.c` — دمج عند نقطة checkin (G25) + استثناء SafeMode لـ TrollStore (G24)
- `roothidehooks/` — حزمة theos roothide
- Sileo/Zebra/RootHide Manager: debs roothide الرسمية

## البناء (يتطلب macOS + Xcode كامل)
```bash
# 0) توليد strapfile مرقّع من procursus طازج:
scripts/prep_strapfile.sh bootstrap.tar.zst out.tar.zst \
    ~/Hermes/projects/Dopamine2-RootHide-latest/Application/Dopamine/Resources/bootstrap_1900.tar.zst
# ضع الناتج في Application/Dopamine/Resources/bootstrap_1900.tar.zst

# 1) BaseBin ثم التطبيق:
make -C BaseBin
make package   # أو make عبر Makefile الجذر
```
ملاحظة: خطوة [4/5] في prep_strapfile (ترقيع Mach-O) تعمل على macOS فقط.

## ما لم يُختبر بعد (تجربة على الجهاز)
1. سلوك roothider dyld_patch على iOS 18.3.2 فعلياً
2. توافق ElleKit-roothide مع trust cache عبر PPL primitives
3. تمرير SafeMode env عبر jbroot المخفي عملياً
4. ترقيم dyld slots لكل target (15 / 16-17 / 18+) — راجع G-DH ملحق الخطة

## سجل القرارات المعمارية (الخطة الكاملة)
`.hermes/plans/2026-08-22_203500-dopamine3-roothide-port.md` — 44 غابز موثقة بحلولها (G9, G21-G44...).
