import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Control {
    id: ci

    padding: Kirigami.Units.smallSpacing

    property string cover: ""

    Kirigami.Icon {
        anchors.centerIn: parent
        source: "emblem-music-symbolic"
    }

    Image {
        id: coverImage
        anchors.fill: parent
        source: ci.cover
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: "white"
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        source: coverImage
        anchors.fill: coverImage
        maskEnabled: true
        maskSource: mask
    }
}
