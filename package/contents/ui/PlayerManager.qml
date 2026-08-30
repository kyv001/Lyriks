import QtQuick
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: pm
    visible: false

    // 被动事件
    signal start(double position) // -1 代表没有时间信息
    signal pause
    signal seek(double seekTimeUs)
    signal metaChanged(var metadata)
    signal playerExited
    // 主动事件
    signal doStart
    signal doPause
    signal doSkipBackward
    signal doSkipForward

    property list<string> players: []
    property string selectedPlayer: ""

    onDoStart: function () {
        if (selectedPlayer !== "") {
            DBus.SessionBus.asyncCall({
                service: selectedPlayer,
                path: "/org/mpris/MediaPlayer2",
                iface: "org.mpris.MediaPlayer2.Player",
                member: "Play",
                arguments: []
            });
        }
    }

    onDoPause: function () {
        if (selectedPlayer !== "") {
            DBus.SessionBus.asyncCall({
                service: selectedPlayer,
                path: "/org/mpris/MediaPlayer2",
                iface: "org.mpris.MediaPlayer2.Player",
                member: "Pause",
                arguments: []
            });
        }
    }

    onDoSkipBackward: function () {
        if (selectedPlayer !== "") {
            DBus.SessionBus.asyncCall({
                service: selectedPlayer,
                path: "/org/mpris/MediaPlayer2",
                iface: "org.mpris.MediaPlayer2.Player",
                member: "Previous",
                arguments: []
            });
        }
    }

    onDoSkipForward: function () {
        if (selectedPlayer !== "") {
            DBus.SessionBus.asyncCall({
                service: selectedPlayer,
                path: "/org/mpris/MediaPlayer2",
                iface: "org.mpris.MediaPlayer2.Player",
                member: "Next",
                arguments: []
            });
        }
    }

    Component.onCompleted: {
        DBus.SessionBus.asyncCall({
            service: "org.freedesktop.DBus",
            path: "/org/freedesktop/DBus",
            iface: "org.freedesktop.DBus",
            member: "ListNames",
            arguments: []
        },
        // success
        function (reply) {
            pm.players = reply.value.filter(name => (name.startsWith("org.mpris.MediaPlayer2.")));
            if (!pm.players.includes(pm.selectedPlayer)) {
                pm.selectedPlayer = pm.players.length > 0 ? pm.players[0] : "";
            }
        },
        // error
        function (error) {
            console.warn("Error getting players: " + error.message);
        });
    }

    DBus.SignalWatcher {
        id: seekWatcher
        busType: DBus.BusType.Session
        service: pm.selectedPlayer
        enabled: pm.selectedPlayer !== ""
        path: "/org/mpris/MediaPlayer2"
        iface: "org.mpris.MediaPlayer2.Player"

        function dbusSeeked(position) {
            pm.seek(position);
        }
    }

    DBus.SignalWatcher {
        id: nameWatcher
        busType: DBus.BusType.Session
        service: "org.freedesktop.DBus"
        path: "/org/freedesktop/DBus"
        iface: "org.freedesktop.DBus"

        function dbusNameOwnerChanged(name, oldOwner, newOwner) {
            name = String(name);
            oldOwner = String(oldOwner);
            newOwner = String(newOwner);
            let playerCountBefore = pm.players.length;
            if (newOwner === "") { // 播放器下线
                pm.players = pm.players.filter(player => player !== name);
            } else if (oldOwner === "" && name.startsWith("org.mpris.MediaPlayer2.") && !pm.players.includes(name)) { // 播放器上线
                pm.players.push(name);
            }
            if (!pm.players.includes(pm.selectedPlayer)) { // 若当前播放器是空或者已经下线，重新分配一个播放器
                pm.selectedPlayer = pm.players.length > 0 ? pm.players[0] : "";
            }
            if (pm.players.length === 0 && playerCountBefore > 0) {
                pm.selectedPlayer = "";
                pm.playerExited();
            }
        }
    }

    DBus.Properties {
        id: playerProperties
        busType: DBus.BusType.Session
        service: pm.selectedPlayer
        path: "/org/mpris/MediaPlayer2"
        iface: "org.mpris.MediaPlayer2.Player"

        Component.onCompleted: {
            if (pm.selectedPlayer !== "") {
                updateAll();
            }
        }
        onPropertiesChanged: updateAll()
        onRefreshed: pm.processProperties(properties)
    }

    function processProperties(properties) {
        if ("PlaybackStatus" in properties) {
            if (String(properties.PlaybackStatus) === "Playing") {
                pm.start(properties.Position ?? -1);
            } else {
                pm.pause();
            }
        }
        if ("Metadata" in properties) {
            pm.metaChanged(properties["Metadata"]);
        }
    }
}
