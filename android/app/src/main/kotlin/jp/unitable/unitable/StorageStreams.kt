package net.neomenia.unitable

import java.io.InputStream
import java.io.OutputStream
import java.security.MessageDigest

internal class StorageFailure(val code: String) : IllegalStateException(code)

internal object StorageStreams {
    // Keep in sync with lib/data/database_security.dart.
    const val maxDatabaseBytes = 32L * 1024 * 1024

    fun checkSize(size: Long) {
        if (size > maxDatabaseBytes) throw StorageFailure("storageFileTooLarge")
    }

    // Count actual bytes: provider metadata and source file sizes can change.
    fun copy(input: InputStream, output: OutputStream, limit: Long = maxDatabaseBytes): Long {
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (true) {
            val count = input.read(buffer)
            if (count < 0) return total
            if (count == 0) continue
            if (total > limit - count) throw StorageFailure("storageFileTooLarge")
            output.write(buffer, 0, count)
            total += count
        }
    }

    fun digest(input: InputStream): ByteArray {
        val digest = MessageDigest.getInstance("SHA-256")
        copy(input, object : OutputStream() {
            override fun write(value: Int) { digest.update(value.toByte()) }
            override fun write(bytes: ByteArray, offset: Int, length: Int) {
                digest.update(bytes, offset, length)
            }
        })
        return digest.digest()
    }
}
