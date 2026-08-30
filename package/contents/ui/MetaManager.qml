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
        onFetchFinished: function (cover, title, artists, player) {
            if (mm.artists.toString() === artists.toString() && mm.title === title) {
                mm.cover = cover;
            }
        }
    }

    Connections {
        target: mm.pm
        function onMetaChanged(metadata) {
            if ("xesam:title" in metadata && mm.title !== String(metadata["xesam:title"])) {
                let artists = [];
                if ("xesam:artist" in metadata) {
                    artists = metadata["xesam:artist"];
                } else if ("xesam:albumArtist" in metadata) {
                    artists = metadata["xesam:albumArtist"];
                }
                if (artists.length === 1) {
                    artists = String(artists[0]).split(" / ");
                }
                mm.artists = artists;
                mm.title = String(metadata["xesam:title"]);
                mm.trackChanged(mm.title, mm.artists);
                mm.clear();
                if ("xesam:length" in metadata) {
                    mm.lengthUs = metadata["xesam:length"];
                } else {
                    mm.lengthUs = 0;
                }
                lf.startFetch(mm.title, mm.artists, mm.pm.selectedPlayer, mm.lengthUs);

                if ("mpris:artUrl" in metadata) {
                    console.log("COVER PROVIDED, SKIPPED FETCHING");
                    mm.cover = metadata["mpris:artUrl"];
                } else {
                    cf.startFetch(mm.title, mm.artists, mm.pm.selectedPlayer, mm.lengthUs);
                }
            }
        }

        function onPlayerExited() {
            mm.clear();
        }
    }

    function clear() {
        mm.lyrics = [];
        mm.cover = "";
        mm.lengthUs = 0;
    }
}
