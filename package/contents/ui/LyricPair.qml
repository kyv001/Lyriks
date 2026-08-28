pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: lp
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
            easing: lp.easingMode
        }
    }

    onEnd: {
        disappearAnimation.running = true;
    }

    LyricLine {
        id: primary

        y: parent.height * 0.5
        height: parent.height * 0.5
        scale: 2 / 3
        transformOrigin: Item.Left

        tl: lp.tl
        primaryWords: lp.primaryWords
        viewWidth: lp.width
    }

    LyricLine {
        id: secondary

        y: parent.height * 1
        height: parent.height * 0.5
        scale: 2 / 3
        transformOrigin: Item.Left

        tl: lp.tl
        primaryWords: lp.secondaryWords
        viewWidth: lp.width
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
            easing: lp.easingMode
        }
        PropertyAnimation {
            target: primary
            property: "y"
            to: 0
            duration: 250
            easing: lp.easingMode
        }
        PropertyAnimation {
            target: primary
            property: "scale"
            to: 1
            duration: 250
            easing: lp.easingMode
        }

        // Secondary
        PropertyAnimation {
            target: secondary
            property: "opacity"
            to: 0.75
            duration: 250
            easing: lp.easingMode
        }
        PropertyAnimation {
            target: secondary
            property: "y"
            to: lp.height * 0.5
            duration: 250
            easing: lp.easingMode
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
                easing: lp.easingMode
            }
            PropertyAnimation {
                target: primary
                property: "y"
                to: lp.height * -0.5
                duration: 250
                easing: lp.easingMode
            }

            // Secondary
            PropertyAnimation {
                target: secondary
                property: "opacity"
                to: 0
                duration: 250
                easing: lp.easingMode
            }
            PropertyAnimation {
                target: secondary
                property: "scale"
                to: 1
                duration: 250
                easing: lp.easingMode
            }
            PropertyAnimation {
                target: secondary
                property: "y"
                to: 0
                duration: 250
                easing: lp.easingMode
            }
        }

        ScriptAction {
            script: {
                lp.destroy();
            }
        }
    }
}
