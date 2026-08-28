pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Row {
    id: ll
    opacity: 0
    spacing: 0 // 每个词已经自带空格

    required property TimeLine tl
    required property list<var> primaryWords
    required property double viewWidth

    Component {
        id: primaryWordComponent
        Item {
            id: primaryWordRoot
            required property string text
            required property double t0Us
            required property double t1Us
            height: parent.height
            width: background.implicitWidth
            Label {
                id: background
                height: parent.height
                font.pixelSize: 0.75 * Kirigami.Units.gridUnit
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignLeft
                text: parent.text
                color: Kirigami.Theme.disabledTextColor
            }
            Label {
                id: foreground
                height: parent.height
                font.pixelSize: 0.75 * Kirigami.Units.gridUnit
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignLeft
                text: parent.text
                color: "white"
                visible: false
            }
            Item {
                id: mask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle {
                    width: {
                        if (ll.primaryWords.length === 1) {
                            return parent.width; // 并非逐词
                        }
                        if (ll.tl.progressUs < primaryWordRoot.t0Us) {
                            return 0;
                        } else if (primaryWordRoot.t0Us >= primaryWordRoot.t1Us || ll.tl.progressUs >= primaryWordRoot.t1Us) {
                            return parent.width;
                        }
                        return (ll.tl.progressUs - primaryWordRoot.t0Us) / (primaryWordRoot.t1Us - primaryWordRoot.t0Us) * parent.width;
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: 50
                        }
                    }
                    height: parent.height
                    color: "white"
                }
            }
            MultiEffect {
                source: foreground
                anchors.fill: parent
                maskEnabled: true
                maskSource: mask
            }
        }
    }

    Component.onCompleted: {
        for (let i = 0; i < primaryWords.length; i++) {
            let word = primaryWords[i];
            primaryWordComponent.createObject(ll, {
                text: word.text,
                t0Us: word.t0 * 1000,
                t1Us: word.t1 * 1000
            });
        }
    }

    PropertyAnimation {
        id: primaryAnimation
        target: ll
        property: "x"
        from: 0
        to: ll.width > ll.viewWidth ? ll.viewWidth - ll.width : 0
        duration: {
            let words = ll.primaryWords;
            if (words.length === 0)
                return 0;
            return Math.min(1000, words[words.length - 1].t1 - words[0].t0);
        }
        running: false
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: {
            let words = ll.primaryWords;
            if (words.length === 0) {
                running = false;
                return;
            }
            if (ll.tl.progressUs > (words[words.length - 1].t1 + words[0].t0 - primaryAnimation.duration) / 2 * 1000) {
                primaryAnimation.running = true;
                running = false;
            }
        }
    }
}
