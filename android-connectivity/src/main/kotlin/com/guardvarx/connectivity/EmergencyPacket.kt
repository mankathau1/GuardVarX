package com.guardvarx.connectivity

import java.nio.ByteBuffer
import java.util.UUID

/**
 * Compact Emergency BLE packet structure (13 bytes)
 * Fits in standard BLE advertisement legacy packets without truncation.
 */
data class EmergencyPacket(
    val protocolVersion: Byte = 0x01,
    val latitude: Double,
    val longitude: Double,
    val hopCount: Byte = 0x01,
    val hopLimit: Byte = 0x03,
    val emergencyType: Byte = 0x01
) {
    fun toBinary(): ByteArray {
        val buffer = ByteBuffer.allocate(13)
        buffer.put(protocolVersion)
        buffer.putInt((latitude * 1e6).toInt())
        buffer.putInt((longitude * 1e6).toInt())
        buffer.put(hopCount)
        buffer.put(hopLimit)
        buffer.put(emergencyType)
        return buffer.array()
    }

    companion object {
        fun fromBinary(bytes: ByteArray): EmergencyPacket? {
            if (bytes.size < 13) return null
            val buffer = ByteBuffer.wrap(bytes)
            val version = buffer.get()
            val lat = buffer.int / 1e6
            val lng = buffer.int / 1e6
            val hops = buffer.get()
            val limit = buffer.get()
            val type = buffer.get()
            return EmergencyPacket(version, lat, lng, hops, limit, type)
        }
    }
}
