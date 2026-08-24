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
    property double tStartUs: 0 // 倒推的起始时间，单位为微秒，不代表真实播放起始时间；用double防止整数溢出
    property double progressUs: 0 // 当前播放进度，单位为微秒；用double防止整数溢出
    property list<var> lyrics: [] // list<{ t: int, text: string }> 时间单位为微秒，仅存储开始时间
    property bool playing: false

    // UI
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

    // logic
    Component.onCompleted: {
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

    DBus.SignalWatcher {
        id: seekWatcher
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

    DBus.SignalWatcher {
        id: nameWatcher
        busType: DBus.BusType.Session
        service: "org.freedesktop.DBus"
        path: "/org/freedesktop/DBus"
        iface: "org.freedesktop.DBus"

        function dbusNameOwnerChanged(name, oldOwner, newOwner) {
            name = String(name)
            oldOwner = String(oldOwner)
            newOwner = String(newOwner)
            if (newOwner === "") { // 播放器下线
                lyriks.players = lyriks.players.filter((player) => player !== name)
            } else if (oldOwner === "" && name.startsWith("org.mpris.MediaPlayer2.") && !lyriks.players.includes(name)) { // 播放器上线
                lyriks.players.push(name)
            }
            if (!lyriks.players.includes(lyriks.selectedPlayer)) { // 若当前播放器是空或者已经下线，重新分配一个播放器
                lyriks.selectedPlayer = lyriks.players.length > 0 ? lyriks.players[0] : ""
            }
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
                lyriks.lyrics = []
                fetchLyricsTimer.retryCount = 0
                fetchLyricsTimer.running = true
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
        let fetchTitle = lyriks.title
        if (lyriks.title === "" || lyriks.selectedPlayer === "") return
        if (lyriks.selectedPlayer.indexOf("splayer") !== -1) { // SPlayer 有自己的 API ，用不着上网查歌词
            let xhr = new XMLHttpRequest()
            xhr.timeout = 1000
            xhr.open("GET", "http://127.0.0.1:14558/api/lyrics")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    fetchLyricsTimer.requestFinished = true
                    if (xhr.status === 200) {
                        const respLyrics = JSON.parse(xhr.responseText)["lyric"]
                        let lyrics = []
                        for (let i = 0; i < respLyrics.length; i++) {
                            let lyricLine = ""
                            const words = respLyrics[i]["words"]
                            for (let j = 0; j < words.length; j++) { // 暂时不处理逐字歌词，直接拼接
                                lyricLine += words[j]["word"]
                            }
                            lyrics.push({
                                t: respLyrics[i]["startTime"] * 1000,
                                text: lyricLine
                            })
                        }
                        if (lyriks.title === fetchTitle) lyriks.lyrics = lyrics // 防止过时歌词覆盖
                    }
                }
            }
            xhr.send()
        }
    }

    Timer {
        id: fetchLyricsTimer
        interval: 250
        running: false
        repeat: true

        property int retryCount: 0
        property bool requestFinished: true

        onTriggered: function() {
            if (lyriks.lyrics.length > 0 || retryCount >= 3) {
                retryCount = 0
                running = false
                return
            }
            if (!requestFinished) return // 请求还没结束，等下一个循环
            requestFinished = false
            lyriks.fetchLyrics()
            retryCount += 1
        }
    }

    Timer {
        id: updateTimer
        interval: 250
        repeat: true
        running: true
        onTriggered: {
            let date = new Date()
            if (lyriks.playing) {
                lyriks.progressUs = date.getTime() * 1000 - lyriks.tStartUs
                let latestLine = { t: 0, text: "" }
                for (let i = 0; i < lyriks.lyrics.length; i++) {
                    const selectedLine = lyriks.lyrics[i]
                    if (lyriks.progressUs >= selectedLine.t && selectedLine.t > latestLine.t) {
                        latestLine = selectedLine
                    }
                }
                lyriks.lyricLine = latestLine.text
            }
        }
    }
}
