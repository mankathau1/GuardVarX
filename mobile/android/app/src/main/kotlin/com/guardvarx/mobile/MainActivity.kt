package com.guardvarx.mobile

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.*
import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.ParcelUuid
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.guardvarx/connectivity"
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var toneGenerator: ToneGenerator? = null
    private var isAdvertising = false
    private var isScanning = false

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            isAdvertising = true
        }

        override fun onStartFailure(errorCode: Int) {
            isAdvertising = false
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            // Process emergency peer packet, check hop limit, suppress duplicates
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> {
                    val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                    val adapter = btManager?.adapter
                    result.success(adapter?.isEnabled == true)
                }

                "startBleAdvertising" -> {
                    val incidentId = call.argument<String>("incident_id") ?: ""
                    val emergencyType = call.argument<String>("emergency_type") ?: ""
                    val lat = call.argument<Double>("latitude") ?: 0.0
                    val lng = call.argument<Double>("longitude") ?: 0.0

                    val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                    val adapter = btManager?.adapter
                    if (adapter == null || !adapter.isEnabled) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    bluetoothLeAdvertiser = adapter.bluetoothLeAdvertiser
                    if (bluetoothLeAdvertiser == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    val settings = AdvertiseSettings.Builder()
                        .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
                        .setConnectable(false)
                        .setTimeout(0)
                        .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                        .build()

                    // Pack compact emergency packet (UUID + lat + lng + type + hops)
                    val buffer = ByteBuffer.allocate(13)
                    buffer.put(0x01) // Protocol v1
                    buffer.putInt((lat * 1e6).toInt())
                    buffer.putInt((lng * 1e6).toInt())
                    buffer.put(0x01) // Hop count 1
                    buffer.put(0x03) // Hop limit 3
                    buffer.put(0x01) // Emergency type

                    val pUuid = ParcelUuid(UUID.fromString("0000FEAA-0000-1000-8000-00805F9B34FB"))
                    val data = AdvertiseData.Builder()
                        .setIncludeDeviceName(false)
                        .setIncludeTxPowerLevel(false)
                        .addServiceData(pUuid, buffer.array())
                        .build()

                    bluetoothLeAdvertiser?.startAdvertising(settings, data, advertiseCallback)
                    result.success(true)
                }

                "stopBleAdvertising" -> {
                    bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
                    isAdvertising = false
                    result.success(true)
                }

                "startBleScanning" -> {
                    val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                    val adapter = btManager?.adapter
                    bluetoothLeScanner = adapter?.bluetoothLeScanner
                    if (bluetoothLeScanner != null) {
                        val settings = ScanSettings.Builder()
                            .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
                            .build()
                        bluetoothLeScanner?.startScan(null, settings, scanCallback)
                        isScanning = true
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }

                "stopBleScanning" -> {
                    bluetoothLeScanner?.stopScan(scanCallback)
                    isScanning = false
                    result.success(true)
                }

                "triggerLoudSiren" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    if (enable) {
                        if (toneGenerator == null) {
                            toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
                        }
                        toneGenerator?.startTone(ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK, 5000)
                    } else {
                        toneGenerator?.stopTone()
                    }
                    result.success(true)
                }

                "sendFallbackSms" -> {
                    val phone = call.argument<String>("phone") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    try {
                        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }
                        smsManager.sendTextMessage(phone, null, message, null, null)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
