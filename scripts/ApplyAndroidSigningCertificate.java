import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.HexFormat;

// Reuse the app's private key with the public release certificate, including in CI.
class ApplyAndroidSigningCertificate {
    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            throw new IllegalArgumentException("Expected: keystore alias public-certificate.pem");
        }
        char[] storePassword = password("ANDROID_STORE_PASSWORD");
        char[] keyPassword = password("ANDROID_KEY_PASSWORD");
        try {
            Path storePath = Path.of(args[0]).toAbsolutePath().normalize();
            KeyStore store = KeyStore.getInstance(storePath.toFile(), storePassword);
            X509Certificate replacement;
            try (var input = Files.newInputStream(Path.of(args[2]))) {
                replacement = (X509Certificate) CertificateFactory.getInstance("X.509")
                        .generateCertificate(input);
            }
            Certificate current = store.getCertificate(args[1]);
            if (current == null || !store.isKeyEntry(args[1])) {
                throw new IllegalArgumentException("Signing alias must contain a private key.");
            }
            replacement.checkValidity();
            if (!replacement.getSubjectX500Principal().equals(replacement.getIssuerX500Principal())) {
                throw new IllegalArgumentException("Release certificate must be self-signed.");
            }
            replacement.verify(replacement.getPublicKey());
            if (!Arrays.equals(current.getPublicKey().getEncoded(), replacement.getPublicKey().getEncoded())) {
                throw new IllegalArgumentException("Release certificate does not match the signing key.");
            }
            if (current.equals(replacement) && store.getCertificateChain(args[1]).length == 1) {
                System.out.println("Release signing certificate is already current.");
                return;
            }
            var privateKey = store.getKey(args[1], keyPassword);
            String fingerprint = HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(current.getEncoded()));
            Path backup = storePath.resolveSibling(storePath.getFileName() + ".backup-" + fingerprint + ".jks");
            if (!Files.exists(backup)) {
                Files.copy(storePath, backup);
            }
            store.setKeyEntry(args[1], privateKey, keyPassword, new Certificate[]{replacement});
            Path temporary = Files.createTempFile(storePath.getParent(), "signing-certificate-", ".tmp");
            try {
                try (var output = Files.newOutputStream(temporary)) {
                    store.store(output, storePassword);
                }
                try {
                    Files.move(temporary, storePath, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
                } catch (AtomicMoveNotSupportedException exception) {
                    Files.move(temporary, storePath, StandardCopyOption.REPLACE_EXISTING);
                }
            } finally {
                Files.deleteIfExists(temporary);
            }
            System.out.println("Applied release signing certificate: " + replacement.getSubjectX500Principal());
        } finally {
            Arrays.fill(storePassword, '\0');
            Arrays.fill(keyPassword, '\0');
        }
    }

    private static char[] password(String name) {
        String value = System.getenv(name);
        if (value == null || value.isEmpty()) {
            throw new IllegalArgumentException("Missing environment variable: " + name);
        }
        return value.toCharArray();
    }
}
