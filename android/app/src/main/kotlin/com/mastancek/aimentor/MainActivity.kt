package com.mastancek.aimentor

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.aimentor.markdown_export/saf"
    private val PICK_DIRECTORY_REQUEST = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
                }
                "writeFile" -> {
                    val directoryUri = call.argument<String>("directoryUri")
                    val relativePath = call.argument<String>("relativePath")
                    val content = call.argument<ByteArray>("content")
                    val mimeType = call.argument<String>("mimeType") ?: "text/markdown"

                    if (directoryUri == null || relativePath == null || content == null) {
                        result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val success = writeFileViaSaf(directoryUri, relativePath, content, mimeType)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("SAF_WRITE_ERROR", "Failed to write file: ${e.message}", null)
                    }
                }
                "deleteDirectory" -> {
                    val directoryUri = call.argument<String>("directoryUri")
                    val relativePath = call.argument<String>("relativePath")

                    if (directoryUri == null || relativePath == null) {
                        result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val success = deleteDirectoryViaSaf(directoryUri, relativePath)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("SAF_DELETE_ERROR", "Failed to delete directory: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Zapíše soubor přes Storage Access Framework
     *
     * @param directoryUri SAF tree URI (content://...)
     * @param relativePath Relativní cesta (např. "tasks/todo.md")
     * @param content Obsah souboru jako ByteArray
     * @param mimeType MIME type souboru
     * @return true pokud uspělo
     */
    private fun writeFileViaSaf(
        directoryUri: String,
        relativePath: String,
        content: ByteArray,
        mimeType: String
    ): Boolean {
        val treeUri = Uri.parse(directoryUri)
        val rootDir = DocumentFile.fromTreeUri(this, treeUri)
            ?: throw Exception("Failed to access directory: $directoryUri")

        // Parse relativePath a vytvoř vnořené složky
        val pathParts = relativePath.split("/")
        val fileName = pathParts.last()
        val folderPath = pathParts.dropLast(1)

        // Vytvoř vnořené složky (např. "tasks")
        var currentDir = rootDir
        for (folderName in folderPath) {
            val existingFolder = currentDir.findFile(folderName)
            currentDir = if (existingFolder != null && existingFolder.isDirectory) {
                existingFolder
            } else {
                currentDir.createDirectory(folderName)
                    ?: throw Exception("Failed to create directory: $folderName")
            }
        }

        // Vytvoř nebo přepiš soubor
        val existingFile = currentDir.findFile(fileName)
        val targetFile = if (existingFile != null) {
            // Přepiš existující soubor
            existingFile
        } else {
            // Vytvoř nový soubor
            currentDir.createFile(mimeType, fileName)
                ?: throw Exception("Failed to create file: $fileName")
        }

        // Zapsat obsah
        contentResolver.openOutputStream(targetFile.uri, "wt")?.use { outputStream ->
            outputStream.write(content)
            outputStream.flush()
        } ?: throw Exception("Failed to open output stream for: $fileName")

        return true
    }

    /**
     * Smaže složku přes Storage Access Framework
     *
     * @param directoryUri SAF tree URI
     * @param relativePath Relativní cesta ke složce (např. "tasks")
     * @return true pokud uspělo (nebo složka neexistuje)
     */
    private fun deleteDirectoryViaSaf(
        directoryUri: String,
        relativePath: String
    ): Boolean {
        val treeUri = Uri.parse(directoryUri)
        val rootDir = DocumentFile.fromTreeUri(this, treeUri)
            ?: throw Exception("Failed to access directory: $directoryUri")

        // Parse relativePath a najdi cílovou složku
        val pathParts = relativePath.split("/").filter { it.isNotEmpty() }
        var currentDir = rootDir

        for (folderName in pathParts) {
            val existingFolder = currentDir.findFile(folderName)
            if (existingFolder == null || !existingFolder.isDirectory) {
                // Složka neexistuje - považuj za success (už je smazaná)
                return true
            }
            currentDir = existingFolder
        }

        // Smaž složku rekurzivně
        return currentDir.delete()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == PICK_DIRECTORY_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    // Persistovat permission pro tuto složku
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.success(null)
                }
            } else {
                // User zrušil picker
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
