package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.view.OrientationEventListener
import io.flutter.embedding.engine.systemchannels.PlatformChannel
import io.flutter.plugin.common.EventChannel
import org.junit.Assert.assertEquals
import org.junit.Test
import org.mockito.Mockito.*

class DeviceOrientationListenerTest {
    @Test
    fun attachingAndDisposingWithoutCameraNeverTouchesActivityOrSensors() {
        val activity = mock(Activity::class.java)
        val listener = DeviceOrientationListener(activity)
        listener.onListen(null, mock(EventChannel.EventSink::class.java))
        assertEquals(PlatformChannel.DeviceOrientation.PORTRAIT_UP, listener.getOrientation())
        listener.stop()
        listener.onCancel(null)
        verifyNoInteractions(activity)
    }

    @Test
    fun cameraStartCreatesSensorListenerOnceAndRestartReusesIt() {
        val nativeListener = mock(OrientationEventListener::class.java)
        `when`(nativeListener.canDetectOrientation()).thenReturn(true)
        var created = 0
        val listener = DeviceOrientationListener(mock(Activity::class.java)) {
            created++
            nativeListener
        }
        listener.stop()
        assertEquals(0, created)
        verifyNoInteractions(nativeListener)
        listener.start()
        assertEquals(1, created)
        verify(nativeListener).enable()
        listener.stop()
        verify(nativeListener).disable()
        listener.start()
        assertEquals(1, created)
        verify(nativeListener, times(2)).enable()
    }

    @Test
    fun devicesWithoutOrientationSensorDoNotEnableListener() {
        val nativeListener = mock(OrientationEventListener::class.java)
        `when`(nativeListener.canDetectOrientation()).thenReturn(false)
        val listener = DeviceOrientationListener(mock(Activity::class.java)) { nativeListener }
        listener.start()
        verify(nativeListener, never()).enable()
    }
}
