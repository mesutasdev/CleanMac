# CleanMac

Xcode ve Flutter geliştiricileri için macOS disk temizleyici. DerivedData, simülatörler, build cache ve paket önbelleklerini tarar; son build ve güncel cihaz sembollerini koruyarak güvenle temizler.

Apple **Developer ID** ile imzalanmış ve **notarize** edilmiştir — ek kurulum adımı gerekmez.

> **Uygulamayı kullanmak mı istiyorsun?**  
> Yeşil **Code** butonundan indirdiğin kaynak koddur (Xcode projesi).  
> Hazır uygulama için aşağıdaki **DMG** linkini kullan — repo'yu derlemene gerek yok.

## İndir (DMG)

[![Download CleanMac](https://img.shields.io/badge/Download-CleanMac-blue?style=for-the-badge)](https://github.com/mesutasdev/CleanMac/releases/latest)

veya **[Releases](https://github.com/mesutasdev/CleanMac/releases/latest)** sayfasından en son `CleanMac-x.x.dmg` dosyasını indirin.

| Gereksinim | Değer |
|---|---|
| macOS | 13.0 (Ventura) veya üzeri |
| Mimari | Apple Silicon + Intel (Universal) |

## Kurulum

1. [Releases](https://github.com/mesutasdev/CleanMac/releases/latest) sayfasından en son `.dmg` dosyasını indirin
2. DMG'yi açın
3. **`CleanMac'i Kur.app`** dosyasına çift tıklayın — kurar ve otomatik açar

Manuel: CleanMac'i kapatın → `CleanMac.app` → Applications → açın

## Özellikler

### Önerilen temizlik
- **Eski DerivedData** — artık derlemediğin projelerin build çıktıları (son build korunur)
- **Eski Flutter Build** — `Developer/projects` altındaki eski Flutter build klasörleri
- **Kullanılmayan Simülatörler** — güncelleme sonrası kullanılamayan runtime'lar
- **Eski iOS Device Support** — eski cihaz sembolleri (güncel cihaz korunur)

### İsteğe bağlı
- Xcode Arşivleri (`.xcarchive`)
- Simülatör cache ve log dosyaları

### Dikkatli kullanın
- Son build (DerivedData / Flutter)
- Güncel iOS Device Support sembolleri

### Geri gelen cache'ler
- Xcode, CocoaPods, Flutter Pub, Gradle, npm, Homebrew, Swift Package Manager önbellekleri

## Ekran görüntüsü

Menü çubuğundan veya ana pencereden tarama yapın, kategorilere göre hedefleri seçin ve temizleyin. Her hedefin altında ne silindiği ve etkisi açıklanır.

## Geliştirme

```bash
# Xcode ile aç
open CleanMac.xcodeproj

# Notarize edilmiş DMG oluştur (Developer ID + notary profili gerekir)
./scripts/build-dmg.sh
```

### Dağıtım script'leri

| Script | Açıklama |
|---|---|
| `scripts/install-developer-id-cert.sh` | CSR oluşturur, Apple portalını açar |
| `scripts/import-developer-id-cert.sh` | İndirilen `.cer` dosyasını kurar |
| `scripts/setup-notary-credentials.sh` | Notarizasyon kimlik bilgisini kaydeder |
| `scripts/build-dmg.sh` | Archive → imzalama → DMG → notarizasyon |

## Lisans

Bu proje açık kaynak olarak paylaşılmaktadır. Katkılarınızı bekliyoruz.

## Yazar

**Mesut As** — [mesutas.com](https://mesutas.com) · [TechAs.co](https://techas.co) · [LinkedIn](https://www.linkedin.com/in/mesutasdev)

## Destek

CleanMac ücretsiz ve açık kaynaklıdır. Beğendiysen geliştirmeye destek olabilirsin — zorunlu değil, minnet duyarım.

### Buy Me a Coffee

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-destek%20ol-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://buymeacoffee.com/mesutasdevw)

### Banka havalesi (EnPara)

| | |
|---|---|
| **Hesap Sahibi** | Mesut As |
| **Banka** | EnPara |
| **IBAN** | `TR51 0015 7000 0000 0088 1408 69` |
| **Açıklama** | CleanMac destek *(veya istediğiniz bir not)* |
