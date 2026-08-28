import QtQuick

Item {
    id: mm
    visible: false

    signal trackChanged(string title, list<string> artists)
    required property PlayerManager pm
    property list<string> artists: []
    property string title: ""
    property var lyrics: []
    property string cover: ""
    property double lengthUs: 0

    LyricFetcher {
        id: lf

        onFetchFinished: function (lyrics, title, artists, player) {
            if (mm.artists.toString() === artists.toString() && mm.title === title) {
                mm.lyrics = lyrics;
            }
        }
    }

    CoverFetcher {
        id: cf
        onFetchFinished: function (cover) {
            mm.cover = cover;
        }
    }

    Connections {
        target: mm.pm
        function onMetaChanged(metadata) {
            if ("xesam:title" in metadata && mm.title !== String(metadata["xesam:title"])) {
                if ("xesam:artist" in metadata) {
                    mm.artists = metadata["xesam:artist"];
                }
                mm.title = String(metadata["xesam:title"]);
                mm.trackChanged(mm.title, mm.artists);
                mm.clear();
                if ("xesam:length" in metadata) {
                    mm.lengthUs = metadata["xesam:length"];
                } else {
                    mm.lengthUs = 0;
                }
                lf.startFetch(mm.title, mm.artists, mm.pm.selectedPlayer, mm.lengthUs);
                cf.startFetch(mm.title, mm.artists, mm.pm.selectedPlayer, mm.lengthUs);
            }
        }

        function onPlayerExited() { mm.clear(); }
    }

    function clear() {
        mm.lyrics = [];
        mm.cover = "";
        mm.lengthUs = 0;
    }
}
