pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
    id: lyricPairRoot
    anchors.fill: parent
    clip: true

    signal end

    required property TimeLine tl
    required property list<var> primaryWords
    required property list<var> secondaryWords
    property var easingMode: Easing.InOutQuad
    property bool hovered: false

    opacity: !hovered

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing: lyricPairRoot.easingMode
        }
    }

    onEnd: {
        disappearAnimation.running = true;
    }

    Row {
        id: primary
        y: parent.height * 0.5
        height: parent.height * 0.5
        scale: 2 / 3
        transformOrigin: Item.Left
        opacity: 0
        spacing: 0 // 每个词已经自带空格

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
                            if (lyricPairRoot.tl.progressUs < primaryWordRoot.t0Us) {
                                return 0;
                            } else if (primaryWordRoot.t0Us >= primaryWordRoot.t1Us || lyricPairRoot.tl.progressUs >= primaryWordRoot.t1Us) {
                                return parent.width;
                            }
                            return (lyricPairRoot.tl.progressUs - primaryWordRoot.t0Us) / (primaryWordRoot.t1Us - primaryWordRoot.t0Us) * parent.width;
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
            for (let i = 0; i < lyricPairRoot.primaryWords.length; i++) {
                let word = lyricPairRoot.primaryWords[i];
                primaryWordComponent.createObject(primary, {
                    text: word.text,
                    t0Us: word.t0 * 1000,
                    t1Us: word.t1 * 1000
                });
            }
        }

        PropertyAnimation {
            id: primaryAnimation
            target: primary
            property: "x"
            from: 0
            to: primary.width > lyricPairRoot.width ? lyricPairRoot.width - primary.width : 0
            duration: {
                let words = lyricPairRoot.primaryWords;
                return Math.min(500, words[words.length - 1].t1 - words[0].t0);
            }
            running: false
        }

        Timer {
            interval: 250
            repeat: true
            running: true
            onTriggered: {
                let words = lyricPairRoot.primaryWords;
                if (lyricPairRoot.tl.progressUs > (words[words.length - 1].t1 + words[0].t0 - primaryAnimation.duration) / 2 * 1000) {
                    primaryAnimation.running = true;
                    running = false
                }
            }
        }
    }

    Row {
        id: secondary
        y: parent.height * 1
        height: parent.height * 0.5
        scale: 2 / 3
        transformOrigin: Item.Left
        opacity: 0

        Component {
            id: secondaryWordComponent
            Label {
                height: parent.height
                font.pixelSize: 0.75 * Kirigami.Units.gridUnit
            }
        }

        Component.onCompleted: {
            for (let i = 0; i < lyricPairRoot.secondaryWords.length; i++) {
                let word = lyricPairRoot.secondaryWords[i];
                secondaryWordComponent.createObject(secondary, {
                    text: word.text
                });
            }
        }
    }

    ParallelAnimation {
        id: appearAnimation
        running: true
        // Primary
        PropertyAnimation {
            target: primary
            property: "opacity"
            to: 1
            duration: 250
            easing: lyricPairRoot.easingMode
        }
        PropertyAnimation {
            target: primary
            property: "y"
            to: 0
            duration: 250
            easing: lyricPairRoot.easingMode
        }
        PropertyAnimation {
            target: primary
            property: "scale"
            to: 1
            duration: 250
            easing: lyricPairRoot.easingMode
        }

        // Secondary
        PropertyAnimation {
            target: secondary
            property: "opacity"
            to: 0.75
            duration: 250
            easing: lyricPairRoot.easingMode
        }
        PropertyAnimation {
            target: secondary
            property: "y"
            to: lyricPairRoot.height * 0.5
            duration: 250
            easing: lyricPairRoot.easingMode
        }
    }

    SequentialAnimation {
        id: disappearAnimation
        running: false

        ParallelAnimation {
            // Primary
            PropertyAnimation {
                target: primary
                property: "opacity"
                to: 0
                duration: 250
                easing: lyricPairRoot.easingMode
            }
            PropertyAnimation {
                target: primary
                property: "y"
                to: lyricPairRoot.height * -0.5
                duration: 250
                easing: lyricPairRoot.easingMode
            }

            // Secondary
            PropertyAnimation {
                target: secondary
                property: "opacity"
                to: 0
                duration: 250
                easing: lyricPairRoot.easingMode
            }
            PropertyAnimation {
                target: secondary
                property: "scale"
                to: 1
                duration: 250
                easing: lyricPairRoot.easingMode
            }
            PropertyAnimation {
                target: secondary
                property: "y"
                to: 0
                duration: 250
                easing: lyricPairRoot.easingMode
            }
        }

        ScriptAction {
            script: {
                lyricPairRoot.destroy();
            }
        }
    }
}
