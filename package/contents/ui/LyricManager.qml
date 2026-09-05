import QtQuick

Item {
    id: lm
    visible: false

    required property MetaManager mm
    required property TimeLine tl
    property int lastIndex: -1

    signal updateLyrics(list<var> primary, list<var> secondary, bool isTranslated)

    Connections {
        target: lm.mm
        function onTrackChanged(metadata) {
            lm.lastIndex = -1;
        }
    }

    Timer {
        id: updateTimer
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            const date = new Date();
            let latestLine = {
                t: -1,
                words: []
            };
            let latestLineIndex = -1;
            for (let i = 0; i < lm.mm.lyrics.length; i++) {
                const selectedLine = lm.mm.lyrics[i];
                if (lm.tl.progressUs >= selectedLine.t * 1000 && selectedLine.t > latestLine.t) {
                    latestLine = selectedLine;
                    latestLineIndex = i;
                }
            }
            if (latestLineIndex !== -1 && latestLineIndex !== lm.lastIndex) {
                let isTranslated = false;
                let primary = latestLine.words;
                let secondary = lm.mm.lyrics[latestLineIndex + 1]?.words ?? [];
                if (latestLine.trans && latestLine.trans.length > 0) {
                    secondary = latestLine.trans;
                    isTranslated = true;
                }
                lm.updateLyrics(primary, secondary, isTranslated);
                lm.lastIndex = latestLineIndex;
            }
        }
    }
}
