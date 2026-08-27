import QtQuick

Item {
    id: lm

    required property PlayerManager pm
    required property MetaManager mm
    required property TimeLine tl
    property int lastIndex: -1

    signal updateLyrics(string primary, string secondary)

    Connections {
        target: lm.pm
        function onTrackChanged(metadata) {
            lm.lastIndex = -1
        }
    }

    Timer {
        id: updateTimer
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            const date = new Date()
            if (lm.tl.playing) {
                let latestLine = { t: -1, text: "" }
                let latestLineIndex = -1
                for (let i = 0; i < lm.mm.lyrics.length; i++) {
                    const selectedLine = lm.mm.lyrics[i]
                    if (lm.tl.progressUs >= selectedLine.t && selectedLine.t > latestLine.t) {
                        latestLine = selectedLine
                        latestLineIndex = i
                    }
                }
                if (latestLineIndex !== -1 && latestLineIndex !== lm.lastIndex) {
                    lm.updateLyrics(latestLine.text, lm.mm.lyrics[latestLineIndex + 1]?.text ?? "")
                    lm.lastIndex = latestLineIndex
                }
            }
        }
    }
}
