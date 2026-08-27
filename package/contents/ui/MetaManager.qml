import QtQuick

Item {
    id: mm

    signal trackChanged(string title, list<string> artists)
    required property PlayerManager pm
    property list<string> artists: []
    property string title: ""
    property var lyrics: []

    LyricFetcher {
        id: lf

        onFetchFinished: function(lyrics, title, artists, player) {
            if (mm.artists.toString() === artists.toString() && mm.title === title) {
                mm.lyrics = lyrics
            }
        }
    }

    Connections {
        target: mm.pm
        function onMetaChanged(metadata) {
            if ("xesam:title" in metadata && mm.title !== String(metadata["xesam:title"])) {
                if ("xesam:artist" in metadata) {
                    mm.artists = metadata["xesam:artist"]
                }
                mm.title = String(metadata["xesam:title"])
                lf.startFetch(mm.title, mm.artists, mm.pm.selectedPlayer)
                mm.trackChanged(mm.title, mm.artists)
            }
        }
    }
}
