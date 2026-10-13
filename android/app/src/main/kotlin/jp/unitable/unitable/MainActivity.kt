package net.neomenia.unitable

import android.app.Activity
import android.content.Intent
import android.net.Uri
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unitable/storage")
            .setMethodCallHandler { call, result ->
                if (call.method in listOf("pickDocument", "createDocument")) {
                    if (picker != null) { result.error("busy", "ファイル選択中です", null); return@setMethodCallHandler }
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
                                requireNotNull(contentResolver.openInputStream(uri)).use { input ->
                                    target.outputStream().use { input.copyTo(it); it.fd.sync() }
                                }
                                require(target.length() > 0) { "ファイルが空です。" }
                            } else {
                                val bytes = target.readBytes()
                                val original = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                                try {
                                    requireNotNull(contentResolver.openOutputStream(uri, "rwt")).use { it.write(bytes); it.flush() }
                                    val saved = requireNotNull(contentResolver.openInputStream(uri)).use { it.readBytes() }
                                    require(saved.contentEquals(bytes)) { "書き込んだデータを検証できません。" }
                                } catch (e: Exception) {
                                    if (original != null) try { contentResolver.openOutputStream(uri, "rwt")?.use { it.write(original); it.flush() } } catch (_: Exception) { }
                                    throw e
                                }
                            }
                            runOnUiThread { result.success(null) }
                        } catch (e: Exception) { runOnUiThread { result.error("storage", e.message, null) } }
                    }
                    return@setMethodCallHandler
                }
                if (call.method == "pickDirectory") {
                    if (picker != null) { result.error("busy", "フォルダー選択中です", null); return@setMethodCallHandler }
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
                        require(tree.canRead() && tree.canWrite()) { "フォルダーへの読み書き権限がありません。再度選択してください。" }
                        // Recover a crash between moving the old snapshot and publishing the new one.
                        var current = tree.findFile(filename)
                        if (current == null) {
                            val previous = tree.findFile("$filename.previous")
                            if (previous != null) {
                                require(previous.renameTo(filename)) { "前回の保存ファイルを復元できません。" }
                                current = tree.findFile(filename)
                            }
                        }
                        val value: Any? = when (call.method) {
                            "hasDatabase" -> current != null
                            "readDatabase" -> {
                                val document = requireNotNull(current) { "${filename}がありません。" }
                                val target = File(requireNotNull(call.argument<String>("path")))
                                contentResolver.openInputStream(document.uri).use { input ->
                                    requireNotNull(input).use { stream -> target.outputStream().use { stream.copyTo(it); it.fd.sync() } }
                                }
                                require(target.length() > 0) { "データベースが空です。" }
                                null
                            }
                            else -> {
                                val source = File(requireNotNull(call.argument<String>("path")))
                                require(source.exists() && source.length() > 0) { "保存するデータがありません。" }
                                val pending = requireNotNull(tree.createFile("application/octet-stream", "$filename.pending-${UUID.randomUUID()}"))
                                var published = false
                                try {
                                    requireNotNull(contentResolver.openOutputStream(pending.uri, "wt")).use { output ->
                                        source.inputStream().use { it.copyTo(output) }; output.flush()
                                    }
                                    val bytes = requireNotNull(contentResolver.openInputStream(pending.uri)).use { it.readBytes() }
                                    require(bytes.contentEquals(source.readBytes())) { "書き込んだデータを検証できません。" }
                                    tree.findFile("$filename.previous")?.let { require(it.delete()) { "以前のコピーを整理できません。" } }
                                    if (current != null) require(current.renameTo("$filename.previous")) { "このフォルダーは安全な更新に必要なファイル名変更に対応していません。別のローカルフォルダーを選んでください。" }
                                    if (!pending.renameTo(filename)) {
                                        current?.renameTo(filename)
                                        error("データベースの保存を完了できません。")
                                    }
                                    published = true
                                    tree.findFile("$filename.previous")?.delete()
                                } finally { if (!published) pending.delete() }
                                null
                            }
                        }
                        runOnUiThread { result.success(value) }
                    } catch (e: Exception) { runOnUiThread { result.error("storage", e.message, null) } }
                }
            }
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
                require(document.name?.lowercase()?.endsWith(".unitable") == true) { ".unitableファイルを指定してください。" }
                require(document.canRead() && document.canWrite()) { "読み書きできるファイルを指定してください。" }
            }
            val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            contentResolver.takePersistableUriPermission(uri, flags)
            result.success(uri.toString())
        } catch (e: Exception) { result.error("permission", e.message, null) }
    }
}
