package com.quantumrobotix.qrdronecontroller

import android.content.ContentValues
import android.media.*
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.quantumrobotix/video"

    private var mediaCodec: MediaCodec? = null
    private var mediaMuxer: MediaMuxer? = null
    private var videoTrackIndex = -1
    private var muxerStarted = false
    private var frameCount = 0
    private var outputPath: String? = null
    private var isRecording = false
    private val FRAME_RATE = 15
    private val BIT_RATE = 1_000_000
    private var videoWidth = 640
    private var videoHeight = 480

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "startRecording" -> {
                    try {
                        val w = call.argument<Int>("width") ?: 640
                        val h = call.argument<Int>("height") ?: 480
                        startRecording(w, h)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_ERROR", e.message, null)
                    }
                }

                "addFrame" -> {
                    try {
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes != null && isRecording) {
                            addJpegFrame(bytes)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        // Non-fatal — skip frame
                        result.success(false)
                    }
                }

                "stopRecording" -> {
                    try {
                        val savedPath = stopRecording()
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startRecording(width: Int, height: Int) {
        videoWidth = width
        videoHeight = height
        frameCount = 0
        muxerStarted = false
        videoTrackIndex = -1

        // Create output file in cache
        val cacheDir = cacheDir
        outputPath = "${cacheDir.absolutePath}/drone_${System.currentTimeMillis()}.mp4"

        // Setup MediaCodec H264 encoder
        val format = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC,
            videoWidth,
            videoHeight
        ).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar)
            setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
            setInteger(MediaFormat.KEY_FRAME_RATE, FRAME_RATE)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        mediaCodec = MediaCodec.createEncoderByType(
            MediaFormat.MIMETYPE_VIDEO_AVC)
        mediaCodec!!.configure(format, null, null,
            MediaCodec.CONFIGURE_FLAG_ENCODE)
        mediaCodec!!.start()

        mediaMuxer = MediaMuxer(outputPath!!,
            MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        isRecording = true
    }

    private fun addJpegFrame(jpegBytes: ByteArray) {
        val codec = mediaCodec ?: return
        val muxer = mediaMuxer ?: return

        // Decode JPEG to bitmap then to YUV
        val bitmap = android.graphics.BitmapFactory.decodeByteArray(
            jpegBytes, 0, jpegBytes.size) ?: return

        // Scale to encoder size if needed
        val scaled = if (bitmap.width != videoWidth ||
            bitmap.height != videoHeight) {
            android.graphics.Bitmap.createScaledBitmap(
                bitmap, videoWidth, videoHeight, false)
        } else bitmap

        // Convert to NV21 YUV
        val yuv = bitmapToNV21(scaled, videoWidth, videoHeight)
        if (bitmap != scaled) bitmap.recycle()
        scaled.recycle()

        // Feed to encoder
        val inputIndex = codec.dequeueInputBuffer(10_000)
        if (inputIndex >= 0) {
            val inputBuffer = codec.getInputBuffer(inputIndex) ?: return
            inputBuffer.clear()
            inputBuffer.put(yuv)
            val presentationTimeUs =
                frameCount.toLong() * 1_000_000L / FRAME_RATE
            codec.queueInputBuffer(
                inputIndex, 0, yuv.size, presentationTimeUs, 0)
            frameCount++
        }

        // Drain encoder output
        drainEncoder(muxer, false)
    }

    private fun drainEncoder(muxer: MediaMuxer, endOfStream: Boolean) {
        val codec = mediaCodec ?: return
        val bufferInfo = MediaCodec.BufferInfo()

        if (endOfStream) {
            val inputIndex = codec.dequeueInputBuffer(10_000)
            if (inputIndex >= 0) {
                codec.queueInputBuffer(
                    inputIndex, 0, 0,
                    frameCount.toLong() * 1_000_000L / FRAME_RATE,
                    MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            }
        }

        while (true) {
            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, 10_000)
            when {
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) break
                }
                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (!muxerStarted) {
                        videoTrackIndex = muxer.addTrack(
                            codec.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                }
                outputIndex >= 0 -> {
                    val outputBuffer = codec.getOutputBuffer(outputIndex)
                    if (outputBuffer != null &&
                        bufferInfo.size > 0 &&
                        bufferInfo.flags and
                        MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                        if (muxerStarted && videoTrackIndex >= 0) {
                            outputBuffer.position(bufferInfo.offset)
                            outputBuffer.limit(
                                bufferInfo.offset + bufferInfo.size)
                            muxer.writeSampleData(
                                videoTrackIndex, outputBuffer, bufferInfo)
                        }
                    }
                    codec.releaseOutputBuffer(outputIndex, false)
                    if (bufferInfo.flags and
                        MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        break
                    }
                }
            }
        }
    }

    private fun stopRecording(): String? {
        if (!isRecording) return null
        isRecording = false

        try {
            val muxer = mediaMuxer
            val codec = mediaCodec

            if (codec != null && muxer != null) {
                drainEncoder(muxer, true)
                codec.stop()
                codec.release()
                if (muxerStarted) muxer.stop()
                muxer.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            mediaCodec = null
            mediaMuxer = null
            muxerStarted = false
            videoTrackIndex = -1
        }

        val path = outputPath ?: return null

        // Save to gallery via MediaStore
        return try {
            saveToGallery(path)
            path
        } catch (e: Exception) {
            path // Return path even if gallery save fails
        }
    }

    private fun saveToGallery(filePath: String) {
        val file = File(filePath)
        if (!file.exists()) return

        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME,
                "drone_${System.currentTimeMillis()}.mp4")
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_DCIM}/QR Drone Controller")
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }

        val resolver = contentResolver
        val uri = resolver.insert(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
            ?: return

        resolver.openOutputStream(uri)?.use { out ->
            file.inputStream().use { it.copyTo(out) }
        }

        values.clear()
        values.put(MediaStore.Video.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        file.delete()
    }

    // Convert Bitmap to NV21 format for MediaCodec
    private fun bitmapToNV21(
        bitmap: android.graphics.Bitmap,
        width: Int, height: Int
    ): ByteArray {
        val argb = IntArray(width * height)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)

        val yuv = ByteArray(width * height * 3 / 2)
        val yLen = width * height

        for (j in 0 until height) {
            for (i in 0 until width) {
                val pixel = argb[j * width + i]
                // Correct channel order: ARGB packed int
                val r = (pixel shr 16) and 0xFF
                val g = (pixel shr 8) and 0xFF
                val b = pixel and 0xFF

                // Y channel
                val y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                yuv[j * width + i] = y.clamp(16, 235).toByte()

                // UV channels — only for even pixels
                if (j % 2 == 0 && i % 2 == 0) {
                    val u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128
                    val uvIndex = yLen + (j / 2) * width + i
                    if (uvIndex + 1 < yuv.size) {
                        // NV12: U then V
                        yuv[uvIndex] = u.clamp(16, 240).toByte()
                        yuv[uvIndex + 1] = v.clamp(16, 240).toByte()
                    }
                }
            }
        }
        return yuv
    }
    private fun Int.clamp(min: Int, max: Int): Int =
        if (this < min) min else if (this > max) max else this}

//    private fun Int.clamp(min: Int, max: Int): Int =
//        if (this < min) min else if (this > max) max else this