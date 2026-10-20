package net.neomenia.unitable

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.OutputStream
import org.junit.Assert.*
import org.junit.Test

class StorageStreamsTest {
    private class RepeatedInput(private var remaining: Long) : InputStream() {
        override fun read(): Int = if (remaining-- > 0) 42 else -1
        override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
            if (remaining <= 0) return -1
            val count = minOf(remaining, length.toLong()).toInt()
            java.util.Arrays.fill(buffer, offset, offset + count, 42.toByte())
            remaining -= count
            return count
        }
    }

    @Test fun acceptsExactLimitWithoutBufferingWholeFile() {
        val count = StorageStreams.copy(RepeatedInput(StorageStreams.maxDatabaseBytes),
            OutputStream.nullOutputStream())
        assertEquals(StorageStreams.maxDatabaseBytes, count)
    }

    @Test fun rejectsOversizedStreamWithoutWritingPastLimit() {
        var written = 0L
        val output = object : OutputStream() {
            override fun write(value: Int) { written++ }
            override fun write(bytes: ByteArray, offset: Int, length: Int) { written += length }
        }
        val error = assertThrows(StorageFailure::class.java) {
            StorageStreams.copy(RepeatedInput(StorageStreams.maxDatabaseBytes + 1), output)
        }
        assertEquals("storageFileTooLarge", error.code)
        assertTrue(written <= StorageStreams.maxDatabaseBytes)
    }

    @Test fun detectsLimitEvenWithMissingOrWrongSizeMetadata() {
        StorageStreams.checkSize(0) // Metadata cannot bypass counting the stream.
        val output = ByteArrayOutputStream()
        assertThrows(StorageFailure::class.java) {
            StorageStreams.copy(RepeatedInput(17), output, 16)
        }
        assertTrue(output.size() <= 16)
        assertThrows(StorageFailure::class.java) {
            StorageStreams.checkSize(StorageStreams.maxDatabaseBytes + 1)
        }
    }

    @Test fun digestDetectsTruncatedAndChangedData() {
        val expected = StorageStreams.digest(ByteArrayInputStream(byteArrayOf(1, 2, 3)))
        assertArrayEquals(expected,
            StorageStreams.digest(ByteArrayInputStream(byteArrayOf(1, 2, 3))))
        assertFalse(expected.contentEquals(
            StorageStreams.digest(ByteArrayInputStream(byteArrayOf(1, 2)))))
        assertFalse(expected.contentEquals(
            StorageStreams.digest(ByteArrayInputStream(byteArrayOf(1, 2, 4)))))
    }

    @Test fun verificationAlsoRejectsOversizedStreams() {
        assertThrows(StorageFailure::class.java) {
            StorageStreams.digest(RepeatedInput(StorageStreams.maxDatabaseBytes + 1))
        }
    }
}
