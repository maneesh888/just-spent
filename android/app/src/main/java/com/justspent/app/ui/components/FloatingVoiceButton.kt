package com.justspent.app.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Floating action button for voice recording
 * Appears consistently across all app views with circular shadow design
 *
 * @param isRecording Whether currently recording
 * @param hasDetectedSpeech Whether speech has been detected
 * @param hasAudioPermission Whether microphone permission granted
 * @param onStartRecording Callback to start recording
 * @param onStopRecording Callback to stop recording
 * @param onPermissionRequest Callback to request permission
 */
@Composable
fun FloatingVoiceButton(
    isRecording: Boolean,
    hasDetectedSpeech: Boolean,
    hasAudioPermission: Boolean,
    onStartRecording: () -> Unit,
    onStopRecording: () -> Unit,
    onPermissionRequest: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .padding(bottom = 16.dp),
        contentAlignment = Alignment.BottomCenter
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Listening/Processing Indicator (when recording)
            if (isRecording) {
                ListeningIndicator(hasDetectedSpeech = hasDetectedSpeech)
            }

            // Main Floating Action Button
            FloatingActionButton(
                onClick = {
                    if (isRecording) {
                        onStopRecording()
                    } else {
                        if (hasAudioPermission) {
                            onStartRecording()
                        } else {
                            onPermissionRequest()
                        }
                    }
                },
                modifier = Modifier
                    .size(60.dp)
                    .scale(if (isRecording) 1.1f else 1.0f)
                    .testTag("voice_fab"),
                containerColor = if (isRecording)
                    MaterialTheme.colorScheme.error
                else
                    MaterialTheme.colorScheme.primary,
                contentColor = Color.White,
                elevation = FloatingActionButtonDefaults.elevation(
                    defaultElevation = 8.dp,
                    pressedElevation = 12.dp
                ),
                shape = CircleShape
            ) {
                Icon(
                    imageVector = if (isRecording) Icons.Filled.Stop else Icons.Filled.Mic,
                    contentDescription = if (isRecording) "Stop Recording" else "Start Recording",
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}

/**
 * Indicator showing listening/processing state
 */
@Composable
private fun ListeningIndicator(hasDetectedSpeech: Boolean) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(500, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Surface(
        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surfaceVariant,
        tonalElevation = 2.dp,
        shadowElevation = 4.dp
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Pulsing dot indicator
            Surface(
                modifier = Modifier
                    .size(8.dp)
                    .scale(scale),
                shape = CircleShape,
                color = if (hasDetectedSpeech)
                    MaterialTheme.colorScheme.tertiary
                else
                    MaterialTheme.colorScheme.error
            ) {}

            Text(
                text = if (hasDetectedSpeech) "Processing..." else "Listening...",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Medium,
                color = if (hasDetectedSpeech)
                    MaterialTheme.colorScheme.onSurfaceVariant
                else
                    MaterialTheme.colorScheme.error
            )
        }
    }

    // Auto-stop message
    Text(
        text = "Will stop automatically",
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
    )
}
