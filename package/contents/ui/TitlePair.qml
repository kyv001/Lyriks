import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: titlePairRoot
    anchors.fill: parent
    clip: true

    signal end

    required property string primaryText
    required property string secondaryText
    property var easingMode: Easing.InOutQuad
    property bool hovered: false

    opacity: hovered

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing: titlePairRoot.easingMode
        }
    }

    onEnd: {
        disappearAnimation.running = true;
    }

    Label {
        id: primary
        text: parent.primaryText
        width: parent.width
        y: parent.height * 0.5
        height: parent.height * 0.5
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 0.75 * Kirigami.Units.gridUnit
        scale: 2 / 3
        transformOrigin: Item.Left
        opacity: 0
        clip: true
    }

    Label {
        id: secondary
        text: parent.secondaryText
        width: parent.width
        y: parent.height * 1
        height: parent.height * 0.5
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 0.75 * Kirigami.Units.gridUnit
        scale: 2 / 3
        transformOrigin: Item.Left
        opacity: 0
        clip: true
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
            easing: titlePairRoot.easingMode
        }
        PropertyAnimation {
            target: primary
            property: "y"
            to: 0
            duration: 250
            easing: titlePairRoot.easingMode
        }
        PropertyAnimation {
            target: primary
            property: "scale"
            to: 1
            duration: 250
            easing: titlePairRoot.easingMode
        }

        // Secondary
        PropertyAnimation {
            target: secondary
            property: "opacity"
            to: 0.75
            duration: 250
            easing: titlePairRoot.easingMode
        }
        PropertyAnimation {
            target: secondary
            property: "y"
            to: titlePairRoot.height * 0.5
            duration: 250
            easing: titlePairRoot.easingMode
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
                easing: titlePairRoot.easingMode
            }
            PropertyAnimation {
                target: primary
                property: "y"
                to: titlePairRoot.height * -0.5
                duration: 250
                easing: titlePairRoot.easingMode
            }

            // Secondary
            PropertyAnimation {
                target: secondary
                property: "opacity"
                to: 0
                duration: 250
                easing: titlePairRoot.easingMode
            }
            PropertyAnimation {
                target: secondary
                property: "scale"
                to: 1
                duration: 250
                easing: titlePairRoot.easingMode
            }
            PropertyAnimation {
                target: secondary
                property: "y"
                to: 0
                duration: 250
                easing: titlePairRoot.easingMode
            }
        }

        ScriptAction {
            script: {
                titlePairRoot.destroy();
            }
        }
    }
}
