/// App configuration that is not secret. Override at build time with
/// --dart-define=SIGNER_URL=... (e.g. the prod Worker in Milestone 9).
abstract final class AppConfig {
  /// Cloudflare Worker that signs Cloudinary uploads (see worker/).
  static const signerUrl = String.fromEnvironment(
    'SIGNER_URL',
    defaultValue: 'https://tanktrail-signer-dev.syedamuntahapk.workers.dev/sign',
  );
}
