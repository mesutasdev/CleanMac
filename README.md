# CleanMac

Xcode ve Flutter geliştiricileri için macOS disk temizleyici. DerivedData, simülatörler, build cache ve paket önbelleklerini tarar; son build ve güncel cihaz sembollerini koruyarak güvenle temizler.

Apple **Developer ID** ile imzalanmış ve **notarize** edilmiştir — ek kurulum adımı gerekmez.

> **Uygulamayı kullanmak mı istiyorsun?**  
> Yeşil **Code** butonundan indirdiğin kaynak koddur (Xcode projesi).  
> Hazır uygulama için aşağıdaki **DMG** linkini kullan — repo'yu derlemene gerek yok.

## İndir (DMG)

[![Download CleanMac 1.0](https://img.shields.io/badge/Download-CleanMac%201.0-blue?style=for-the-badge)](https://github.com/mesutasdev/CleanMac/releases/download/v1.0/CleanMac-1.0.dmg)

veya **[Releases](https://github.com/mesutasdev/CleanMac/releases/latest)** sayfasından `CleanMac-1.0.dmg` dosyasını indirin.

| Gereksinim | Değer |
|---|---|
| macOS | 13.0 (Ventura) veya üzeri |
| Mimari | Apple Silicon + Intel (Universal) |

## Kurulum

1. `CleanMac-1.0.dmg` dosyasını indirin
2. DMG'yi açın
3. `CleanMac.app` dosyasını **Applications** klasörüne sürükleyin
4. Uygulamayı açın

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

**Mesut As** — [LinkedIn](https://www.linkedin.com/in/mesutasdev)
