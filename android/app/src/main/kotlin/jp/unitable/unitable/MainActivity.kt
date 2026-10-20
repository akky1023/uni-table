package net.neomenia.unitable

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var picker: MethodChannel.Result? = null
    private val io = Executors.newSingleThreadExecutor()
    private val filename = "university.unitable"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unitable/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "openAppSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName")))
                    result.success(null)
                } catch (e: Exception) {
                    result.error("settings", e.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unitable/storage")
            .setMethodCallHandler { call, result ->
                if (call.method in listOf("pickDocument", "createDocument")) {
                    if (picker != null) { result.error("storagePickerBusy", null, null); return@setMethodCallHandler }
                    picker = result
                    val create = call.method == "createDocument"
                    val intent = Intent(if (create) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        putExtra(Intent.EXTRA_LOCAL_ONLY, true)
                        type = "application/octet-stream"
                        if (!create) type = "*/*"
                        if (create) putExtra(Intent.EXTRA_TITLE, filename)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    }
                    try { startActivityForResult(intent, if (create) 7203 else 7202) }
                    catch (e: Exception) { picker = null; result.error("picker", e.message, null) }
                    return@setMethodCallHandler
                }
                if (call.method in listOf("readDocument", "writeDocument")) {
                    io.execute {
                        try {
                            val uri = Uri.parse(requireNotNull(call.argument<String>("uri")))
                            val target = File(requireNotNull(call.argument<String>("path")))
                            if (call.method == "readDocument") {
                                readDocument(uri, target)
                                require(target.length() > 0) { throw StorageFailure("storageEmptyFile") }
                            } else {
                                writeDocument(uri, target)
                            }
                            runOnUiThread { result.success(null) }
                        } catch (e: Exception) { runOnUiThread { result.error((e as? StorageFailure)?.code ?: "storage", e.message, null) } }
                    }
                    return@setMethodCallHandler
                }
                if (call.method == "pickDirectory") {
                    if (picker != null) { result.error("storagePickerBusy", null, null); return@setMethodCallHandler }
                    picker = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        putExtra("android.content.extra.SHOW_ADVANCED", true)
                    }
                    try { startActivityForResult(intent, 7201) }
                    catch (e: Exception) { picker = null; result.error("picker", e.message, null) }
                    return@setMethodCallHandler
                }
                if (call.method !in listOf("hasDatabase", "readDatabase", "writeDatabase")) {
                    result.notImplemented(); return@setMethodCallHandler
                }
                io.execute {
                    try {
                        val uri = Uri.parse(requireNotNull(call.argument<String>("tree")))
                        val tree = requireNotNull(DocumentFile.fromTreeUri(this, uri))
                        require(tree.canRead() && tree.canWrite()) { throw StorageFailure("storageFolderPermission") }
                        // Recover a crash between moving the old snapshot and publishing the new one.
                        var current = tree.findFile(filename)
                        if (current == null) {
                            val previous = tree.findFile("$filename.previous")
                            if (previous != null) {
                                require(previous.renameTo(filename)) { throw StorageFailure("storageRecoveryFailed") }
                                current = tree.findFile(filename)
                            }
                        }
                        val value: Any? = when (call.method) {
                            "hasDatabase" -> current != null
                            "readDatabase" -> {
                                val document = requireNotNull(current) { throw StorageFailure("storageMissingDatabase") }
                                val target = File(requireNotNull(call.argument<String>("path")))
                                readDocument(document.uri, target)
                                require(target.length() > 0) { throw StorageFailure("storageEmptyDatabase") }
                                null
                            }
                            else -> {
                                val source = File(requireNotNull(call.argument<String>("path")))
                                require(source.exists() && source.length() > 0) { throw StorageFailure("storageNoData") }
                                StorageStreams.checkSize(source.length())
                                val pending = requireNotNull(tree.createFile("application/octet-stream", "$filename.pending-${UUID.randomUUID()}"))
                                var published = false
                                try {
                                    requireNotNull(contentResolver.openOutputStream(pending.uri, "wt")).use { output ->
                                        source.inputStream().use { StorageStreams.copy(it, output) }; output.flush()
                                    }
                                    verifyDocument(pending.uri, source)
                                    tree.findFile("$filename.previous")?.let { require(it.delete()) { throw StorageFailure("storageCleanupFailed") } }
                                    if (current != null) require(current.renameTo("$filename.previous")) { throw StorageFailure("storageRenameUnsupported") }
                                    if (!pending.renameTo(filename)) {
                                        current?.renameTo(filename)
                                        throw StorageFailure("storageSaveFailed")
                                    }
                                    published = true
                                    tree.findFile("$filename.previous")?.delete()
                                } finally { if (!published) pending.delete() }
                                null
                            }
                        }
                        runOnUiThread { result.success(value) }
                    } catch (e: Exception) { runOnUiThread { result.error((e as? StorageFailure)?.code ?: "storage", e.message, null) } }
                }
            }
    }

    private fun readDocument(uri: Uri, target: File) {
        try {
            requireNotNull(contentResolver.openInputStream(uri)).use { input ->
                target.outputStream().use { StorageStreams.copy(input, it); it.fd.sync() }
            }
        } catch (e: Exception) {
            target.delete() // Never retain a partial or oversized import.
            throw e
        }
    }

    private fun verifyDocument(uri: Uri, source: File) {
        val expected = source.inputStream().use { StorageStreams.digest(it) }
        val actual = requireNotNull(contentResolver.openInputStream(uri)).use { StorageStreams.digest(it) }
        require(expected.contentEquals(actual)) { throw StorageFailure("storageVerificationFailed") }
    }

    private fun writeDocument(uri: Uri, source: File) {
        StorageStreams.checkSize(source.length())
        // Obtain a bounded recovery copy before touching the original document.
        val backup = File.createTempFile("unitable-backup-", ".tmp", cacheDir)
        try {
            readDocument(uri, backup)
            try {
                requireNotNull(contentResolver.openOutputStream(uri, "rwt")).use { output ->
                    source.inputStream().use { StorageStreams.copy(it, output) }; output.flush()
                }
                verifyDocument(uri, source)
            } catch (e: Exception) {
                try {
                    requireNotNull(contentResolver.openOutputStream(uri, "rwt")).use { output ->
                        backup.inputStream().use { StorageStreams.copy(it, output) }; output.flush()
                    }
                } catch (_: Exception) { /* Working DB remains available for retry. */ }
                throw e
            }
        } finally { backup.delete() }
    }

    @Deprecated("Android compatibility callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode !in listOf(7201, 7202, 7203)) return
        val result = picker ?: return
        picker = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) { result.success(null); return }
        try {
            val uri = data.data!!
            if (requestCode != 7201) {
                val document = requireNotNull(DocumentFile.fromSingleUri(this, uri))
                require(document.name?.lowercase()?.endsWith(".unitable") == true) { throw StorageFailure("storageSelectFile") }
                require(document.canRead() && document.canWrite()) { throw StorageFailure("storageFilePermission") }
            }
            val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            contentResolver.takePersistableUriPermission(uri, flags)
            result.success(uri.toString())
        } catch (e: Exception) { result.error((e as? StorageFailure)?.code ?: "permission", e.message, null) }
    }
}
