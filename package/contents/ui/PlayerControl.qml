import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: pc

    required property PlayerManager pm
    required property TimeLine tl

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Button {
        Layout.fillHeight: true
        Layout.preferredWidth: height
        icon.name: "media-skip-backward"
        onClicked: pc.pm.doSkipBackward()
    }

    Button {
        Layout.fillHeight: true
        Layout.preferredWidth: height
        icon.name: pc.tl.playing ? "media-playback-pause" : "media-playback-start"

        onClicked: {
            pc.tl.playing ? pc.pm.doPause() : pc.pm.doStart();
        }
    }

    Button {
        Layout.fillHeight: true
        Layout.preferredWidth: height
        icon.name: "media-skip-forward"
        onClicked: pc.pm.doSkipForward()
    }
}
