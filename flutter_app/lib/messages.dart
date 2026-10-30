// Motorun hata kodlari (docs/IPC.md) icin kullaniciya gosterilen Turkce mesajlar.

enum ErrorAction { relaunchAdmin, defenderGuide, retry }

class ErrorInfo {
  final String title;
  final String body;
  final ErrorAction? action;
  const ErrorInfo(this.title, this.body, [this.action]);
}

const _defender = 'Windows Defender veya başka bir antivirüs WinDivert sürücüsünü engellemiş olabilir. '
    'Uygulama klasörünü dışlamalara ekleyip tekrar deneyin.';

ErrorInfo errorInfo(String? code) => switch (code) {
      'admin_required' => const ErrorInfo('Yönetici izni yok',
          'phevy paketleri yönlendirebilmek için yönetici olarak çalışmalıdır.', ErrorAction.relaunchAdmin),
      'driver_missing' => const ErrorInfo('WinDivert dosyaları eksik',
          'Sürücü dosyaları bulunamadı; büyük ihtimalle antivirüs sildi. $_defender', ErrorAction.defenderGuide),
      'driver_blocked' =>
        const ErrorInfo('Sürücü engellendi', _defender, ErrorAction.defenderGuide),
      'driver_signature' => const ErrorInfo('Sürücü imzası doğrulanamadı',
          'Windows sürücünün imzasını kabul etmedi. Güvenli Önyükleme / Bellek Bütünlüğü ayarları buna yol açabilir.',
          ErrorAction.defenderGuide),
      'driver_conflict' => const ErrorInfo('Başka bir DPI aracı açık',
          'GoodbyeDPI, zapret veya başka bir WinDivert aracı çalışıyor. Onu kapatıp tekrar deneyin.',
          ErrorAction.retry),
      'bfe_stopped' => const ErrorInfo('Windows filtre servisi kapalı',
          '"Base Filtering Engine" (BFE) servisi çalışmıyor. Hizmetler\'den başlatıp tekrar deneyin.',
          ErrorAction.retry),
      'no_internet' => const ErrorInfo('İnternet bağlantısı yok',
          'Kontrol sitesine erişilemedi. Bağlantınızı kontrol edip tekrar deneyin.', ErrorAction.retry),
      'engine_missing' => const ErrorInfo('Motor bulunamadı',
          'phevy_engine.exe bulunamadı; antivirüs silmiş olabilir. $_defender', ErrorAction.defenderGuide),
      'engine_exited' => const ErrorInfo('Motor kapandı',
          'Arka plandaki phevy motoru beklenmedik şekilde kapandı. Logları inceleyin.', ErrorAction.retry),
      'driver_error' => const ErrorInfo('Sürücü açılamadı',
          'WinDivert sürücüsü başlatılamadı. Ayrıntı aşağıda ve loglarda.', ErrorAction.retry),
      _ => const ErrorInfo('Beklenmeyen hata', 'Bir şeyler ters gitti. Logları paylaşın.', ErrorAction.retry),
    };

/// Bagliyken gelebilen uyari kodlari.
String? warningText(String? code) => switch (code) {
      'no_strategy_found' => 'Hiçbir yöntem testten geçemedi; varsayılan yöntemle çalışılıyor. Discord açılmayabilir.',
      'rescan_no_internet' => 'Yeniden tarama sırasında internet yoktu; mevcut yöntemle devam ediliyor.',
      _ => null,
    };
