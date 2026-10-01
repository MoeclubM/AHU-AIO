package com.example.ahu_aio

import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val wechatChannel = "com.example.ahu_aio/wechat_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wechatChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "isWeChatInstalled" -> {
                    try {
                        packageManager.getPackageInfo("com.tencent.mm", 0)
                        result.success(true)
                    } catch (e: PackageManager.NameNotFoundException) {
                        result.success(false)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "launchWeChat" -> {
                    try {
                        val intent = packageManager.getLaunchIntentForPackage("com.tencent.mm")
                        if (intent != null) {
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

