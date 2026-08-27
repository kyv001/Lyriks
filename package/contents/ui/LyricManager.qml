import QtQuick

Item {
    id: lm

    required property MetaManager mm
    required property TimeLine tl
    property int lastIndex: -1

    signal updateLyrics(string primary, string secondary)

    Connections {
        target: lm.mm
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
                let primary = latestLine.text
                let secondary = lm.mm.lyrics[latestLineIndex + 1]?.text ?? ""
                if (latestLine.trans !== "") {
                    secondary = latestLine.trans
                }
                lm.updateLyrics(primary, secondary)
                lm.lastIndex = latestLineIndex
            }
        }
    }
}
