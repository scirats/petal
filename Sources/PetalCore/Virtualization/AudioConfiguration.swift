import Virtualization

enum AudioConfiguration {
    static func make(input: Bool) -> VZVirtioSoundDeviceConfiguration {
        let sound = VZVirtioSoundDeviceConfiguration()

        let output = VZVirtioSoundDeviceOutputStreamConfiguration()
        output.sink = VZHostAudioOutputStreamSink()
        sound.streams = [output]

        if input {
            let microphone = VZVirtioSoundDeviceInputStreamConfiguration()
            microphone.source = VZHostAudioInputStreamSource()
            sound.streams.append(microphone)
        }
        return sound
    }
}
