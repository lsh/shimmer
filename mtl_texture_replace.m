#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>
#include <stdint.h>
#include <string.h>

// Write to CVPixelBuffer
void CVPixelBuffer_writeBytes(CVPixelBufferRef pixelBuffer,
                              const void* pixelBytes,
                              NSUInteger bytesPerRow,
                              NSUInteger width,
                              NSUInteger height) {
    if (!pixelBuffer || !pixelBytes) {
        return;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    void* baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bufferBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);

    if (baseAddress) {
        for (NSUInteger y = 0; y < height; y++) {
            memcpy((uint8_t*)baseAddress + y * bufferBytesPerRow,
                   (const uint8_t*)pixelBytes + y * bytesPerRow,
                   bytesPerRow);
        }
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}
