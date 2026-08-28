import QtQuick

Item {
    id: tl
    visible: false

    required property PlayerManager pm
    property bool playing: false
    property double tStartUs: 0 // 倒推的起始时间，单位为微秒，不代表真实播放起始时间；用double防止整数溢出
    property double progressUs: 0 // 当前播放进度，单位为微秒；用double防止整数溢出

    Connections {
        target: tl.pm

        function onStart(position: double) {
            const date = new Date();
            if (position >= 0) { // -1 代表没有时间信息
                tl.progressUs = position;
            }
            tl.tStartUs = date.getTime() * 1000 - tl.progressUs;
            tl.playing = true;
        }

        function onSeek(position: double) {
            const date = new Date();
            tl.progressUs = position;
            tl.tStartUs = date.getTime() * 1000 - position;
        }

        function onPause() {
            tl.playing = false;
        }
    }

    Timer {
        id: updateTimer
        interval: 250
        repeat: true
        running: true
        onTriggered: {
            const date = new Date();
            if (tl.playing) {
                tl.progressUs = date.getTime() * 1000 - tl.tStartUs;
            }
        }
    }
}
