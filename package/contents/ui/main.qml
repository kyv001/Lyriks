pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: lyriks

    // data
    property list<string> players: []
    property string selectedPlayer: "" // TODO: 下拉框可选择
    property string artist: ""
    property string title: ""
    property string lyricLine: ""
    property int tStartUs: 0 // 倒推的起始时间，单位为微秒，不代表真实播放起始时间
    property int progressUs: 0 // 当前播放进度，单位为微秒
    property list<var> lyrics: [] // list<{ t: int, text: string }> 时间单位为微秒，仅存储开始时间
    property bool playing: false

    // UI
    preferredRepresentation: fullRepresentation

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: 10 * Kirigami.Units.gridUnit
        Layout.minimumHeight: 5 * Kirigami.Units.gridUnit
        Layout.preferredWidth: 30 * Kirigami.Units.gridUnit
        Layout.preferredHeight: 5 * Kirigami.Units.gridUnit

        Label {
            id: titleLabel
            text: {
                if (lyriks.title === "" || lyriks.selectedPlayer === "") {
                    return "Lyriks - Title Goes Here"
                } else {
                    return lyriks.artist + " - " + lyriks.title
                }
            }
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            font.pixelSize: 1.5 * Kirigami.Units.gridUnit
            Layout.preferredHeight: 2 * Kirigami.Units.gridUnit
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            id: lyricsLabel
            text: (lyriks.selectedPlayer === "") ? "Lyrics will appear here" : lyriks.lyricLine
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            font.pixelSize: 1 * Kirigami.Units.gridUnit
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            id: playerLabel
            text: {
                if (lyriks.selectedPlayer === "") {
                    return "No player selected"
                } else {
                    return "Selected Player: " + lyriks.selectedPlayer
                }
            }
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignBottom
            font.pixelSize: 0.75 * Kirigami.Units.gridUnit
            Layout.preferredHeight: 1 * Kirigami.Units.gridUnit
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Component.onCompleted: {
        getPlayers()
    }

    // logic
    function getPlayers() {
        DBus.SessionBus.asyncCall({
            service: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            iface: "org.freedesktop.DBus",
            member: "ListNames",
            arguments: []
        },
        // success
        function(reply) {
            lyriks.players = reply.value.filter((name) => (name.startsWith("org.mpris.MediaPlayer2.")))
            if (!lyriks.players.includes(lyriks.selectedPlayer)) {
                lyriks.selectedPlayer = lyriks.players.length > 0 ? lyriks.players[0] : ""
            }
        },
        // error
        function(error) {
            console.warn("Error getting players: " + error.message)
        })
    }

    DBus.DBusServiceWatcher {
        id: serviceWatcher
        busType: DBus.BusType.Session
        watchedService: "org.mpris.MediaPlayer2.*"
        onRegisteredChanged: {
            lyriks.getPlayers()
            playerProperties.updateAll()
        }
    }

    DBus.SignalWatcher {
        id: signalWatcher
        busType: DBus.BusType.Session
        service: lyriks.selectedPlayer
        enabled: lyriks.selectedPlayer !== ""
        path: "/org/mpris/MediaPlayer2"
        iface: "org.mpris.MediaPlayer2.Player"

        function dbusSeeked(position) {
            let date = new Date()
            lyriks.tStartUs = date.getTime() * 1000 - Number(position)
            lyriks.progressUs = Number(position)
        }
    }

    DBus.Properties {
        id: playerProperties
        busType: DBus.BusType.Session
        service: lyriks.selectedPlayer
        path: "/org/mpris/MediaPlayer2"
        iface: "org.mpris.MediaPlayer2.Player"

        Component.onCompleted: {
            if (lyriks.selectedPlayer !== "") {
                updateAll()
            }
        }
        onPropertiesChanged: updateAll()
        onRefreshed: lyriks.processProperties(properties)
    }

    function processProperties(properties) {
        if ("PlaybackStatus" in properties) {
            lyriks.playing = String(properties.PlaybackStatus) === "Playing"
        }

        if ("Metadata" in properties) {
            let metadata = properties.Metadata
            if ("xesam:title" in metadata && lyriks.title !== String(metadata["xesam:title"])) {
                lyriks.title = String(metadata["xesam:title"])
                let date = new Date()
                lyriks.tStartUs = date.getTime() * 1000
                lyriks.progressUs = 0
                fetchLyrics()
            }
            if ("xesam:artist" in metadata) {
                lyriks.artist = metadata["xesam:artist"].join(" / ")
            }
        }

        if (lyriks.playing && "Position" in properties) {
            let date = new Date()
            lyriks.tStartUs = date.getTime() * 1000 - Number(properties.Position)
            lyriks.progressUs = Number(properties.Position)
        }
    }

    function fetchLyrics() {
        lyriks.lyrics = []
        if (lyriks.title === "" || lyriks.selectedPlayer === "") {
            return
        }
        if (lyriks.selectedPlayer.indexOf("splayer") !== -1) { // SPlayer 有自己的 API ，用不着上网查歌词
            let xhr = new XMLHttpRequest()
            xhr.open("GET", "http://127.0.0.1:14558/api/lyrics")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        var response = JSON.parse(xhr.responseText)
                        for (let i = 0; i < response["lyric"].length; i++) {
                            let lyricLine = ""
                            for (let j = 0; j < response["lyric"][i]["words"].length; j++) { // 暂时不处理逐字歌词，直接拼接
                                lyricLine += response["lyric"][i]["words"][j]["word"]
                            }
                            lyriks.lyrics.push({
                                t: response["lyric"][i]["startTime"] * 1000,
                                text: lyricLine
                            })
                        }
                    }
                }
            }
            xhr.send()
        }
    }

    Timer {
        id: updateTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            let date = new Date()
            if (lyriks.playing) {
                lyriks.progressUs = date.getTime() * 1000 - lyriks.tStartUs
                for (let i = 0; i < lyriks.lyrics.length; i++) {
                    if (lyriks.progressUs <= lyriks.lyrics[i].t) {
                        lyriks.lyricLine = lyriks.lyrics[i - 1]?.text ?? ""
                        break
                    }
                }
            }
        }
    }
}
