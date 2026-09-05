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
                } else if ("xesam:url" in metadata) { // 播放器没有提供艺术家，那就在文件名里提取
                    let fnameSegments = String(metadata["xesam:url"]).replace(/\.[^\.]+$/, '').split(/\s*-\s*/);
                    // /path/to/dir/Title - Author.ext --> /path/to/dir/Title - Author --> [/path/to/dir/Title, Author]
                    //                                                                                          ~~~~~~
                    if (fnameSegments.length > 1) {
                        artists = [fnameSegments[fnameSegments.length - 1]];
                    }
                }
                if (artists.length === 1) {
                    artists = String(artists[0]).split(/\s*[\/,]\s*/);
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
                    mm.cover = String(metadata["mpris:artUrl"]);
                } else {
                    cf.startFetch(mm.title, mm.artists, mm.pm.selectedPlayer, mm.lengthUs);
                }
            } else if ("mpris:artUrl" in metadata && mm.cover !== String(metadata["mpris:artUrl"])) { // 一些播放器（如SPlayer）会稍后再发送封面图
                mm.cover = String(metadata["mpris:artUrl"]);
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
