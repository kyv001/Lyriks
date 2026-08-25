import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: lyricPairRoot
    height: parent.height
    width: parent.width
    clip: true

    property string primaryStr
    property string secondaryStr
    property int activeTime: 0
    property var easingMode: Easing.InOutSine

    Label {
        id: primary
        text: parent.primaryStr
        width: parent.width
        y: parent.height * 0.5
        height: parent.height * 0.5
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 0.5 * Kirigami.Units.gridUnit
        opacity: 0
        clip: true
    }

    Label {
        id: secondary
        text: parent.secondaryStr
        width: parent.width
        y: parent.height * 1
        height: parent.height * 0.5
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 0.5 * Kirigami.Units.gridUnit
        opacity: 0
        clip: true
    }

    ParallelAnimation {
        id: appearAnimation
        running: false
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
            property: "font.pixelSize"
            to: 0.75 * Kirigami.Units.gridUnit
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

    SequentialAnimation{
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
                property: "font.pixelSize"
                to: 0.75 * Kirigami.Units.gridUnit
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
            onStarted: {
                lyricPairRoot.destroy()
            }
        }
    }

    Timer {
        id: animationTimer
        interval: parent.activeTime
        running: true
        repeat: parent.activeTime > 0
        property int counter: 0
        onTriggered: {
            console.log("Triggered: ", parent.primaryStr, parent.secondaryStr)
            if (counter == 0) {
                appearAnimation.start()
                counter = 1
            } else {
                disappearAnimation.start()
                animationTimer.running = false
            }
        }
    }
}
