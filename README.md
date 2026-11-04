<p align="center">
  <img src="assets/banner.webp" alt="OpenWrt on Zyxel NAS326" width="100%">
</p>

# OpenWrt on Zyxel NAS326

**[English](#english) | [Türkçe](#türkçe)**

Tested: **OpenWrt 25.12.6 (r33311-981c978eff)**, Linux 6.12.112, target `mvebu/cortexa9`.
Upstream support commit: [openwrt/openwrt@471dd1b](https://github.com/openwrt/openwrt/commit/471dd1ba15bf13f57fa1c935f8766e520daabfdd)

---

## English

### Hardware

| Component | Specification |
|---|---|
| CPU | Marvell ARMADA 380, 1x 1332 MHz (Cortex-A9) |
| RAM | 512 MB DDR3 |
| Flash | 256 MB NAND (MX30LF2G18AC) |
| Storage | 2x SATA III |
| USB | 2x USB 3.0, 1x USB 2.0 |
| LAN | 1x 1 Gbit (WoL capable) |
| Other | RTC with battery, 9 LEDs, Reset / Power / Copy buttons |

**Not working:** fan control, buzzer.

The stock U-Boot identifies the board as `PRODUCT_NAME=STG-328`, `VENDOR_NAME=MitraStar Technology Corp.`, `MODEL_ID=B303` (MitraStar is Zyxel's ODM). The prompt is `Marvell>>`.

### Files

| File | Purpose | SHA256 |
|---|---|---|
| [`firmware/…-initramfs-kernel.bin`](firmware/openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-initramfs-kernel.bin) | RAM boot via TFTP (first install / recovery) | `14f59321…2d7b305a` |
| [`firmware/…-squashfs-sysupgrade.bin`](firmware/openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-squashfs-sysupgrade.bin) | Permanent install via LuCI or `sysupgrade` | `0413d3c9…c337bcf5` |
| [`firmware/sha256sums`](firmware/sha256sums) | Full checksums | |

The images are unmodified official builds from [downloads.openwrt.org](https://downloads.openwrt.org/releases/25.12.6/targets/mvebu/cortexa9/). Prefer downloading newer versions from there.

### UART

Header **J3**, **115200 8N1**, 3.3 V logic:

```
+------+------+------+------+------+
| 3.3V |  TX  |  RX  |      | GND  |
+------+------+------+------+------+
```

- Connect only **TX, RX, GND**. Do not connect 3.3V.
- With some USB-UART adapters the board does not boot while the adapter is attached (all LEDs dimmed). Unplug the UART for under a second; all LEDs should turn white, then it boots.
- Press **Ctrl-C** within the 3 s window to stop U-Boot. A longer delay helps:
  ```
  setenv bootdelay 7
  saveenv
  ```

### Installation

**1. Prepare a TFTP server on your PC** (e.g. Tftpd64) and put the `initramfs-kernel.bin` in its root folder. Connect the NAS LAN port to the same network.

> If Tftpd64 lives in `C:\Program Files\Tftpd64`, copying into it requires administrator rights.

**2. In U-Boot (`Marvell>>`), boot the initramfs** — replace the IPs with your PC (`serverip`) and a free address for the NAS (`ipaddr`):

```
setenv ethact egiga0
setenv serverip 192.168.1.11
setenv ipaddr 192.168.1.12
tftpboot 0x02000000 openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-initramfs-kernel.bin
bootm 0x02000000 -
```

You should see `Machine model: Zyxel NAS326` in the kernel log, followed by the OpenWrt shell. The device is a **DHCP client** by default — check its address with `ip addr show br-lan`.

**3. Back up the stock firmware** (bank 1) before writing anything:

```
cat /dev/mtd3 > /tmp/Kernel-1.bin
cat /dev/mtd4 > /tmp/RootFS-1.bin
```

Copy them off the device (e.g. via LuCI or `scp`) and keep them somewhere safe.

**4. Install permanently.** Open LuCI at `http://<nas-ip>` → **System → Backup / Flash Firmware → Flash new firmware image** and upload `squashfs-sysupgrade.bin`. Or from the shell:

```
sysupgrade -n /tmp/openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-squashfs-sysupgrade.bin
```

> The initramfs image has no `tftp` client and no HTTP server is guaranteed on the PC, so uploading through LuCI is the easiest way.

**5. Make sure U-Boot boots bank 1 (OpenWrt):**

```
setenv next_bootfrom 1
saveenv
```

### Dual boot

U-Boot has two banks. OpenWrt replaces bank 1; the stock firmware remains in bank 2 (`Kernel-2` / `RootFS-2`, read-only in OpenWrt).

| Boot | Command |
|---|---|
| OpenWrt (bank 1) | `setenv next_bootfrom 1; saveenv` |
| Stock Zyxel (bank 2) | `setenv next_bootfrom 2; saveenv` |

### MAC address

Stored in the U-Boot environment as `ethaddr`; label MAC = eth0 MAC.

### i2c settings

Install `i2c-tools` first (`apk add i2c-tools`).

| Action | Command |
|---|---|
| Enable WoL | `i2cset -y 0x0 0xa 0xa 0x0006 w` |
| Disable WoL | `i2cset -y 0x0 0xa 0xa 0x0306 w` |
| Enable auto power-on | `i2cset -y 0x0 0x0a 0x0a 0x0107 w` |
| Disable auto power-on | `i2cset -y 0x0 0x0a 0x0a 0x0007 w` |

---

## Türkçe

### Donanım

| Bileşen | Özellik |
|---|---|
| CPU | Marvell ARMADA 380, 1x 1332 MHz (Cortex-A9) |
| RAM | 512 MB DDR3 |
| Flash | 256 MB NAND (MX30LF2G18AC) |
| Depolama | 2x SATA III |
| USB | 2x USB 3.0, 1x USB 2.0 |
| LAN | 1x 1 Gbit (WoL destekli) |
| Diğer | Pilli RTC, 9 LED, Reset / Power / Copy tuşları |

**Çalışmayanlar:** fan kontrolü, buzzer.

Orijinal U-Boot kartı `PRODUCT_NAME=STG-328`, `VENDOR_NAME=MitraStar Technology Corp.`, `MODEL_ID=B303` olarak gösterir (MitraStar, Zyxel'in üreticisidir). Prompt `Marvell>>` şeklindedir.

### Dosyalar

| Dosya | Amaç |
|---|---|
| [`firmware/…-initramfs-kernel.bin`](firmware/openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-initramfs-kernel.bin) | TFTP ile RAM'den boot (ilk kurulum / kurtarma) |
| [`firmware/…-squashfs-sysupgrade.bin`](firmware/openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-squashfs-sysupgrade.bin) | LuCI veya `sysupgrade` ile kalıcı kurulum |
| [`firmware/sha256sums`](firmware/sha256sums) | SHA256 değerleri |

İmajlar [downloads.openwrt.org](https://downloads.openwrt.org/releases/25.12.6/targets/mvebu/cortexa9/) adresindeki resmi, değiştirilmemiş dosyalardır. Yeni sürümleri oradan indirmeniz önerilir.

### UART

**J3** konnektörü, **115200 8N1**, 3.3 V:

```
+------+------+------+------+------+
| 3.3V |  TX  |  RX  |      | GND  |
+------+------+------+------+------+
```

- Sadece **TX, RX, GND** bağlayın. 3.3V'u bağlamayın.
- Bazı USB-UART adaptörleri takılıyken cihaz açılmaz (tüm LED'ler sönük). UART'ı bir saniyeden kısa süre çıkarıp takın; LED'ler beyaz olunca boot eder.
- U-Boot'u durdurmak için 3 sn içinde **Ctrl-C**'ye basın. Süreyi uzatmak işinizi kolaylaştırır:
  ```
  setenv bootdelay 7
  saveenv
  ```

### Kurulum

**1. PC'de TFTP sunucusu hazırlayın** (ör. Tftpd64) ve `initramfs-kernel.bin` dosyasını kök dizinine koyun. NAS'ın LAN portunu aynı ağa bağlayın.

> Tftpd64 `C:\Program Files\Tftpd64` altındaysa dosya kopyalamak yönetici izni ister.

**2. U-Boot'ta (`Marvell>>`) initramfs'i boot edin** — `serverip` yerine PC'nizin IP'sini, `ipaddr` yerine NAS için boş bir IP yazın:

```
setenv ethact egiga0
setenv serverip 192.168.1.11
setenv ipaddr 192.168.1.12
tftpboot 0x02000000 openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-initramfs-kernel.bin
bootm 0x02000000 -
```

Kernel log'da `Machine model: Zyxel NAS326` satırını, ardından OpenWrt shell'ini görmelisiniz. Cihaz varsayılan olarak **DHCP istemcisidir** — IP'sini `ip addr show br-lan` ile öğrenin.

**3. Orijinal firmware'i yedekleyin** (bank 1), hiçbir şey yazmadan önce:

```
cat /dev/mtd3 > /tmp/Kernel-1.bin
cat /dev/mtd4 > /tmp/RootFS-1.bin
```

Dosyaları cihazdan alıp (LuCI veya `scp` ile) güvenli bir yerde saklayın.

**4. Kalıcı kurulum.** Tarayıcıdan `http://<nas-ip>` adresindeki LuCI'ye girin → **System → Backup / Flash Firmware → Flash new firmware image** ve `squashfs-sysupgrade.bin` dosyasını yükleyin. Ya da shell'den:

```
sysupgrade -n /tmp/openwrt-25.12.6-mvebu-cortexa9-zyxel_nas326-squashfs-sysupgrade.bin
```

> Initramfs imajında `tftp` istemcisi yok; en kolay yol dosyayı LuCI üzerinden yüklemek.

**5. U-Boot'un bank 1'den (OpenWrt) açtığından emin olun:**

```
setenv next_bootfrom 1
saveenv
```

### Çift boot (dual boot)

U-Boot'ta iki bank vardır. OpenWrt bank 1'e yazılır; orijinal firmware bank 2'de kalır (`Kernel-2` / `RootFS-2`, OpenWrt'de salt okunur).

| Açılış | Komut |
|---|---|
| OpenWrt (bank 1) | `setenv next_bootfrom 1; saveenv` |
| Orijinal Zyxel (bank 2) | `setenv next_bootfrom 2; saveenv` |

### MAC adresi

U-Boot ortamında `ethaddr` olarak saklanır; etiket MAC'i = eth0 MAC'i.

### i2c ayarları

Önce `i2c-tools` kurun (`apk add i2c-tools`).

| İşlem | Komut |
|---|---|
| WoL aç | `i2cset -y 0x0 0xa 0xa 0x0006 w` |
| WoL kapat | `i2cset -y 0x0 0xa 0xa 0x0306 w` |
| Elektrik gelince otomatik açılma: aç | `i2cset -y 0x0 0x0a 0x0a 0x0107 w` |
| Elektrik gelince otomatik açılma: kapat | `i2cset -y 0x0 0x0a 0x0a 0x0007 w` |

---

<sub>OpenWrt is GPL-licensed. Device support by Robert Senderek, merged upstream by Robert Marko and Hauke Mehrtens. Use at your own risk / Risk size aittir.</sub>
