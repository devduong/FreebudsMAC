<div align="center">

# 🎧 FreebudsMAC

**Gestionnaire natif macOS pour écouteurs HUAWEI FreeBuds & HONOR Earbuds**

*100% Swift & SwiftUI • Sans runtime Python • Binaire Universel (Apple Silicon & Intel)*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20(Ventura%20|%20Sonoma%20|%20Sequoia%20|%20Tahoe)-black?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%7C%206.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%20(arm64%20%2B%20x86__64)-purple?style=flat-square)](#)
[![Licence](https://img.shields.io/badge/Licence-GPL--3.0-blue?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Version](https://img.shields.io/badge/Version-0.18.0-success?style=flat-square)](https://github.com/devduong/FreebudsMAC/releases)

---

### 🌐 Langues / Languages / 多语言 / Ngôn ngữ / Языки

[**English**](../README.md) • [**Tiếng Việt**](README_vi.md) • [**简体中文**](README_zh-Hans.md) • [**繁體中文**](README_zh-Hant.md) • [**Русский**](README_ru.md) • [**Français**](README_fr.md)

---

</div>

## ⚠️ Important : Uniquement compatible macOS

> [!IMPORTANT]
> **FreebudsMAC est conçu et optimisé exclusivement pour macOS** (requis macOS 13.0 Ventura ou plus récent, entièrement compatible macOS 14 Sonoma, macOS 15 Sequoia et macOS Tahoe). L'application s'appuie directement sur les frameworks natifs d'Apple (`IOBluetooth`, `CoreBluetooth`, `Carbon.HIToolbox` et `UserNotifications`).
>
> Si vous recherchez une solution pour d'autres systèmes d'exploitation (**Linux** ou **Windows**), veuillez consulter le projet original en Python/PyQt développé par **@melianmiko** :
> 👉 **[https://github.com/melianmiko/OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)**

---

## ✨ Fonctionnalités principales

- 🎛️ **Contrôle complet de la réduction de bruit (ANC)** : Basculez en un clic entre **Réduction de bruit**, **Mode perception (Awareness / Transparence)** et **Désactivé (Normal)**.
- 🔋 **Suivi de la batterie en temps réel** : Affichage précis du niveau de charge de l'écouteur gauche (L), droit (R) và du boîtier (Case) avec statut de charge.
- 👂 **Détection de port (Auto-Pause)** : Mise en pause automatique de la lecture audio lorsque vous retirez un écouteur et reprise dès que vous le remettez.
- 🎚️ **Égaliseur (EQ) & Profils audio** : Choix des profils par défaut, Amplification des basses, Amplification des aigus, Voix et égaliseur personnalisé.
- 🔀 **Double connexion (Dual-Connect / Multipoint)** : Gestion des appareils appairés et bascule rapide de la source audio active.
- 👆 **Personnalisation des gestes tactiles** : Configuration du double-tap, triple-tap, appui long et glissement pour le contrôle du volume.
- ⚡ **Mode faible latence pour le jeu** : Réduction du délai de transmission audio pour le gaming et le montage vidéo.
- ⌨️ **Raccourcis clavier globaux** : Raccourcis système (`⌥⌘A`, `⌥⌘C`, `⌥⌘0`, `⌥⌘1`, `⌥⌘2`, `⌥⌘L`) accessibles depuis n'importe quelle application.
- 🔔 **Notifications de batterie faible auto-masquantes** : Alertes natives discrètes à 20% et 10% (se ferment automatiquement après 3 secondes).
- 🚀 **Performances et légèreté** : Application Swift native ultra-légère, lancement instantané, consommation RAM < 30 Mo et CPU quasi nul.
- 🌐 **Support multilingue** : Interface disponible en Français, Anglais, Vietnamien, Chinois simplifié (简体中文), Chinois traditionnel (繁體中文) et Russe.

---

## 🎧 Écouteurs pris en charge

### Modèles officiellement compatibles

Les modèles ci-dessous disposent de pilotes dédiés et d'une prise en charge complète :

| Gamme | Modèle | Fonctionnalités supportées |
| :--- | :--- | :--- |
| **FreeBuds Pro** | HUAWEI FreeBuds Pro | ANC, Batterie, Détection de port, Gestes, Glissement volume |
| | HUAWEI FreeBuds Pro 2 | ANC, Batterie, Détection de port, EQ, Dual-Connect, Gestes, Faible latence |
| | HUAWEI FreeBuds Pro 3 | ANC, Batterie, Détection de port, EQ, Dual-Connect, Gestes, Faible latence |
| | HUAWEI FreeBuds Pro 4 | ANC, Batterie, Détection de port, EQ, Dual-Connect, Gestes, Faible latence |
| | HUAWEI FreeBuds Pro 5 | ANC, Batterie, Détection de port, EQ, Dual-Connect, Gestes, Faible latence |
| **FreeBuds i** | HUAWEI FreeBuds 4i | ANC, Batterie, Détection de port, Gestes |
| | HUAWEI FreeBuds 5i | ANC, Batterie, Détection de port, EQ, Dual-Connect, Gestes, Faible latence |
| | HUAWEI FreeBuds 6i | ANC, Batterie, Détection de port, EQ, Dual-Connect, Gestes, Faible latence |
| **FreeClip** | HUAWEI FreeClip | Batterie, Détection de port, Dual-Connect, Gestes |
| | HUAWEI FreeClip 2 | Batterie, Détection de port, Dual-Connect, Gestes |
| **FreeBuds SE** | HUAWEI FreeBuds SE | Batterie, Gestes |
| | HUAWEI FreeBuds SE 2 | Batterie, Gestes |
| | HUAWEI FreeBuds SE 4 ANC | ANC, Batterie, Gestes |
| **Studio & Tour de cou** | HUAWEI FreeBuds Studio | ANC, Batterie, Bouton d'alimentation, Gestes |
| | HUAWEI FreeLace Pro | ANC, Batterie, Auto-pause magnétique |
| | HUAWEI FreeLace Pro 2 | ANC, Batterie, Faible latence, Auto-pause |
| **HONOR** | HONOR Earbuds 2 / 2 SE / 2 Lite | ANC, Batterie, Gestes |

### Que faire pour les autres modèles non listés ?

FreebudsMAC intègre un **système de secours intelligent à 3 niveaux** :

1. **Écouteurs HUAWEI / HONOR non répertoriés** :
   - L'application instancie automatiquement le pilote générique **`GenericHuaweiDriver`**.
   - Il charge automatiquement 100% des gestionnaires SPP standards (ANC, Batterie, Gestes, EQ, Dual-Connect).
   - Vous pouvez également désactiver l'option *"Sélection automatique"* dans **Sélection de l'appareil** pour choisir manuellement n'importe quel écouteur appairé.
2. **Écouteurs Bluetooth tiers (Non-Huawei)** :
   - Gérés par le module **`BLEBatteryScanner` / `BLEBatteryDriver`**.
   - Lecture passive du niveau de batterie via les protocoles **Google Fast Pair (`0xFE2C`)** ou le service standard **GATT Battery (`0x180F`)**.

---

## 📥 Installation & Premier lancement

### 1. Télécharger l'image DMG
Téléchargez la dernière version `FreebudsMAC_Universal_x.x.x.dmg` sur la page des [Releases GitHub](https://github.com/devduong/FreebudsMAC/releases).

### 2. Installer l'application
Ouvrez le fichier `.dmg` téléchargé et glissez **FreebudsMAC.app** dans votre dossier **Applications** (`/Applications`).

### 3. Premier lancement et contournement de Gatekeeper

> [!WARNING]
> FreebudsMAC étant un projet open-source communautaire sans certificat payant Apple Developer, la sécurité macOS Gatekeeper peut afficher un message d'avertissement au premier lancement :
> *"Impossible d’ouvrir FreebudsMAC car le développeur ne peut pas être vérifié"* ou *"macOS ne peut pas vérifier que cette app est exempte de logiciels malveillants"*.

**Procédure simple pour ouvrir l'application :**
1. Ouvrez les **Réglages Système** (System Settings) de votre Mac.
2. Allez dans la section **Confidentialité et sécurité** (Privacy & Security).
3. Faites défiler jusqu'à la section **Sécurité** (Security).
4. Cliquez sur le bouton **"Ouvrir quand même" (Open Anyway)** situé à côté de l'avertissement concernant FreebudsMAC.
5. Dans la boîte de dialogue de confirmation, cliquez sur **"Ouvrir"** et saisissez votre mot de passe ou utilisez Touch ID.

*(Astuce : Vous pouvez aussi maintenir la touche `Contrôle` enfoncée (ou clic droit) sur `FreebudsMAC.app` dans le Finder ➔ cliquez sur **Ouvrir** ➔ confirmez avec **Ouvrir**).*

---

## 🛡️ Guide des autorisations système macOS

Pour profiter de toutes les fonctionnalités, ouvrez **Réglages FreebudsMAC > Réglages macOS** et configurez les 3 autorisations :

```
Réglages FreebudsMAC ➔ Réglages macOS
├── 1. Autorisation Bluetooth     ➔ Obligatoire (Communication SPP/BLE avec les écouteurs)
├── 2. Autorisation Notifications ➔ Alertes batterie faible (Style : Bannières)
└── 3. Autorisation Accessibilité ➔ Écoute des raccourcis clavier globaux
```

### 1. 🔵 Autorisation Bluetooth
- **Utilité** : Permet la communication SPP/RFCOMM et BLE pour lire l'état de la batterie et envoyer les ordres de contrôle ANC.
- **Accorder** : Cliquez sur *"Ouvrir les réglages Bluetooth"* ou validez la demande système au démarrage.

### 2. 🔔 Autorisation Notifications (Batterie faible)
- **Utilité** : Recevoir une notification automatique quand la batterie descend à 20% et 10% (la notification disparaît d'elle-même après 3 secondes).
- **Réglage recommandé** :
  - Ouvrez **Réglages Système** ➔ **Notifications** ➔ **FreebudsMAC**.
  - Assurez-vous que le style d'alerte est réglé sur **Bannières (Banners)** pour que les notifications s'affichent correctement dans le coin de l'écran.

### 3. ⌨️ Autorisation Accessibilité (Raccourcis clavier)
- **Utilité** : Permet de capter les combinaisons de touches globales même lorsque l'application s'exécute en arrière-plan dans la barre des menus.
- **Accorder** : Cliquez sur *"Accorder l'autorisation d'accessibilité"* dans l'app, puis activez l'interrupteur pour **FreebudsMAC** dans **Confidentialité et sécurité > Accessibilité**.

#### Tableau des raccourcis clavier :

| Raccourci | Action | Description |
| :---: | :--- | :--- |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>A</kbd> | **Changer de mode ANC** | Alterne entre Normal ➔ Réduction de bruit ➔ Perception |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>C</kbd> | **Connecter / Déconnecter** | Connexion ou déconnexion rapide des écouteurs |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>0</kbd> | **Désactiver la réduction** | Mode Normal (ANC désactivé) |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>1</kbd> | **Activer l'ANC** | Réduction de bruit active |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>2</kbd> | **Mode Perception** | Transparence / Perception des voix |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>L</kbd> | **Mode Faible Latence** | Mode jeu vidéo / synchronisation audio optimisée |

---

## 🛠️ Compilation depuis les sources

### Prérequis
- macOS 13.0 (Ventura) ou ultérieur (macOS Sonoma / Sequoia / Tahoe recommandé).
- Outils de ligne de commande Xcode (`xcode-select --install`) avec Swift 5.9+.

### Commandes de compilation & exécution
```bash
# 1. Cloner le dépôt
git clone https://github.com/devduong/FreebudsMAC.git
cd FreebudsMAC

# 2. Compiler en mode Release
swift build -c release

# 3. Lancer l'application
swift run FreebudsMAC
```

---

## 🙏 Remerciements spéciaux

- Un immense merci à **[@melianmiko](https://github.com/melianmiko)**, créateur du projet original **[OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)** en Python/PyQt, pour sa documentation minutieuse du protocole Bluetooth SPP Huawei et l'ingénierie inverse des paquets de commandes.
- Merci à l'ensemble des contributeurs de la communauté open-source pour les travaux sur les protocoles Fast Pair et les structures de paquets Bluetooth Huawei/Honor.

---

## ☕ Soutien & Dons

FreebudsMAC est un logiciel entièrement gratuit et open-source sous licence GPL-3.0. Si ce projet vous est utile au quotidien sur votre Mac, vous pouvez soutenir son développement :

<div align="center">

[![Soutenir sur Ko-fi](https://img.shields.io/badge/Soutenir_sur-Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/X4P324ZPZ3)
[![Étoile sur GitHub](https://img.shields.io/badge/Star_sur-GitHub-yellow?style=for-the-badge&logo=github&logoColor=black)](https://github.com/devduong)

</div>

### 🪙 Don en Cryptomonnaie (BEP20 / Binance Smart Chain)

Vous pouvez envoyer des tokens compatibles BEP20 (USDT, BNB, BUSD, ETH, BTC, etc.) à l'adresse suivante :

```text
Réseau (Network) : BEP20 (BSC – Binance Smart Chain)
Adresse du portefeuille : 0xe26c0DC422EF744816Ca3B2d210e6214fdC4e18E
```

---

## 📄 Licence

Ce projet est distribué sous licence [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
