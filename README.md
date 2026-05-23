# KVM sous LineageOS / Android (AArch64)

Méthode pour faire fonctionner QEMU/KVM sur un téléphone Android (testé sur **Pixel 7a, LineageOS 21, kernel 6.1**).

## Problème

Le kernel Android rejette les appels `KVM_SET_ONE_REG` pour les registres **DEMUX AArch32** (groupe `KVM_REG_ARM_DEMUX = 0x0011 << 16`), ce qui fait planter QEMU au démarrage de la VM :

```
KVM_SET_ONE_REG failed: Invalid argument
```

Ce comportement est propre au kernel Android patché — le kernel Linux upstream ne pose pas ce problème.

## Solution : LD_PRELOAD

On intercepte `ioctl()` avec une bibliothèque partagée injectée via `LD_PRELOAD`. Quand QEMU tente d'écrire un registre DEMUX, on retourne `0` silencieusement au lieu de laisser passer l'appel au kernel.

```
QEMU → ioctl(KVM_SET_ONE_REG, DEMUX_REG) → [intercepté] → return 0
```

### Pourquoi LD_PRELOAD et pas un patch kernel ?

Le kernel Android est signé et non modifiable. LD_PRELOAD est la solution la moins invasive : aucun root persistant, aucune modification système.

---

## Prérequis

- **Termux** installé
- **`/dev/kvm`** accessible (LineageOS avec KVM built-in)
- **QEMU** installé dans Termux : `pkg install qemu-system-aarch64`
- **gcc/clang** pour compiler : `pkg install clang`

### Rendre /dev/kvm accessible

Par défaut `/dev/kvm` appartient à `root`. Il faut le rendre accessible à Termux :

```sh
# À exécuter en root (ADB shell ou Magisk)
chmod 666 /dev/kvm
```

Pour automatiser au boot via **Termux:Boot** : voir [`scripts/boot/kvm_fix.sh`](scripts/boot/kvm_fix.sh).

---

## Compilation du fix

```sh
cd kvm_reg_fix
make
```

Ou manuellement :

```sh
clang -shared -fPIC -O2 -o kvm_reg_fix4.so kvm_reg_fix4.c -ldl
```

Le fichier `kvm_reg_fix4.so` produit est la bibliothèque à injecter.

---

## Utilisation

Préfixer la commande QEMU avec `LD_PRELOAD` :

```sh
env LD_PRELOAD=/path/to/kvm_reg_fix4.so \
  qemu-system-aarch64 \
    -machine virt,accel=kvm \
    -cpu host,pmu=off \
    -m 4096 \
    -smp 6 \
    ...
```

Voir [`scripts/start-ubuntu.sh`](scripts/start-ubuntu.sh) pour un exemple complet avec Ubuntu Server arm64.

---

## Scripts fournis

| Fichier | Rôle |
|---|---|
| `kvm_reg_fix/kvm_reg_fix4.c` | Source du fix LD_PRELOAD |
| `kvm_reg_fix/Makefile` | Compilation |
| `scripts/start-ubuntu.sh` | Lancement manuel de la VM |
| `scripts/boot/kvm_fix.sh` | Boot Termux:Boot — chmod /dev/kvm |
| `scripts/boot/ubuntu-vm.sh` | Boot Termux:Boot — démarre la VM automatiquement |

---

## Détails techniques

### Pourquoi les registres DEMUX posent problème

QEMU tente d'initialiser les registres DEMUX lors de la création du vCPU AArch64 en mode compatible AArch32. Le kernel Android 6.1 refuse ces écritures avec `EINVAL`. Ces registres ne sont pas nécessaires pour faire tourner un OS AArch64 (Ubuntu arm64, Alpine, etc.) — les ignorer est sans danger.

### Ce qui ne fonctionne PAS (solutions écartées)

| Tentative | Pourquoi ça échoue |
|---|---|
| `kvm_reg_fix.so` / `fix2` / `fix3` | Mauvais numéro ioctl, mauvaise constante groupe, sign-extension int→ulong — l'interception ne matchait jamais |
| Patch kernel | Kernel Android signé, non modifiable |
| `-cpu cortex-a53` (sans `-accel kvm`) | Fonctionne mais ~10× plus lent (émulation pure) |

### Constantes clés

```c
KVM_SET_ONE_REG      = 0x4010aeac   // ioctl request
KVM_REG_ARM_COPROC_MASK = 0x000F0000000000ULL
KVM_REG_ARM_DEMUX    = 0x00110000000000ULL  // groupe cible
```

---

## Testé sur

| Appareil | SoC | Kernel | Android |
|---|---|---|---|
| Google Pixel 7a | Tensor G2 (AArch64) | 6.1.145-android14 | LineageOS 21 (Android 14) |

Contributions bienvenues pour d'autres appareils.

---

## Licence

MIT
