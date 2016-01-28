//
//  AKPhaseLockedVocoderDSPKernel.hpp
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

#ifndef AKPhaseLockedVocoderDSPKernel_hpp
#define AKPhaseLockedVocoderDSPKernel_hpp

#import "AKDSPKernel.hpp"
#import "AKParameterRamper.hpp"

#import <AudioKit/AudioKit-Swift.h>

extern "C" {
#include "soundpipe.h"
}

enum {
    positionAddress = 0,
    amplitudeAddress = 1,
    pitchRatioAddress = 2
};

class AKPhaseLockedVocoderDSPKernel : public AKDSPKernel {
public:
    // MARK: Member Functions

    AKPhaseLockedVocoderDSPKernel() {}

    void init(int channelCount, double inSampleRate) {
        channels = channelCount;

        sampleRate = float(inSampleRate);
        sp_create(&sp);
        sp_mincer_create(&mincer);

    }

    void start() {
        started = true;
        sp_mincer_init(sp, mincer, ftbl);
        mincer->time = 0;
        mincer->amp = 1;
        mincer->pitch = 1;
    }

    void stop() {
        started = false;
    }
    
    void setUpTable(float *table, UInt32 size) {
        ftbl_size = size;
        sp_ftbl_create(sp, &ftbl, ftbl_size);
        ftbl->tbl = table;
    }

    void destroy() {
        sp_mincer_destroy(&mincer);
        sp_destroy(&sp);
    }

    void reset() {
    }

    void setPosition(float time) {
        position = time;
        positionRamper.set(clamp(time, (float)0, (float)1000000));
    }

    void setAmplitude(float amp) {
        amplitude = amp;
        amplitudeRamper.set(clamp(amp, (float)0, (float)1));
    }

    void setPitchratio(float pitch) {
        pitchRatio = pitch;
        pitchRatioRamper.set(clamp(pitch, (float)-1000, (float)1000));
    }


    void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
            case positionAddress:
                positionRamper.set(clamp(value, (float)0, (float)1000000));
                break;

            case amplitudeAddress:
                amplitudeRamper.set(clamp(value, (float)0, (float)1));
                break;

            case pitchRatioAddress:
                pitchRatioRamper.set(clamp(value, (float)-1000, (float)1000));
                break;

        }
    }

    AUValue getParameter(AUParameterAddress address) {
        switch (address) {
            case positionAddress:
                return positionRamper.goal();

            case amplitudeAddress:
                return amplitudeRamper.goal();

            case pitchRatioAddress:
                return pitchRatioRamper.goal();

            default: return 0.0f;
        }
    }

    void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) override {
        switch (address) {
            case positionAddress:
                positionRamper.startRamp(clamp(value, (float)0, (float)1000000), duration);
                break;

            case amplitudeAddress:
                amplitudeRamper.startRamp(clamp(value, (float)0, (float)1), duration);
                break;

            case pitchRatioAddress:
                pitchRatioRamper.startRamp(value, duration);
                break;

        }
    }

    void setBuffers(AudioBufferList *outBufferList) {
        outBufferListPtr = outBufferList;
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
        // For each sample.
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);
            
            position = double(positionRamper.getStep());
            amplitude = double(amplitudeRamper.getStep());
            pitchRatio = double(pitchRatioRamper.getStep());

            mincer->time = position;
            mincer->amp = amplitude;
            mincer->pitch = pitchRatio;

//            for (int channel = 0; channel < channels; ++channel) {
                float *outL = (float *)outBufferListPtr->mBuffers[0].mData + frameOffset;
                float *outR = (float *)outBufferListPtr->mBuffers[1].mData + frameOffset;
                if (started) {
                    sp_mincer_compute(sp, mincer, NULL, outL);
                    *outR = *outL;
                } else {
                    *outL = 0;
                    *outR = 0;
                }
//            }
        }
    }

    // MARK: Member Variables

private:

    int channels = AKSettings.numberOfChannels;
    float sampleRate = AKSettings.sampleRate;

    AudioBufferList *outBufferListPtr = nullptr;

    sp_data *sp;
    sp_mincer *mincer;
    sp_ftbl *ftbl;
    UInt32 ftbl_size = 4096;

    float position = 0;
    float amplitude = 1;
    float pitchRatio = 1;

public:
    bool started = false;
    AKParameterRamper positionRamper = 0;
    AKParameterRamper amplitudeRamper = 1;
    AKParameterRamper pitchRatioRamper = 1;
};

#endif /* AKPhaseLockedVocoderDSPKernel_hpp */
