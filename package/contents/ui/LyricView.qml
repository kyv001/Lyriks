import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: lv
    Layout.minimumWidth: 10 * Kirigami.Units.gridUnit
    Layout.minimumHeight: 2 * Kirigami.Units.gridUnit
    Layout.preferredHeight: 2 * Kirigami.Units.gridUnit
    Layout.preferredWidth: 20 * Kirigami.Units.gridUnit
    clip: true

    property TitlePair titlePair: null
    property LyricPair currentPair: null

    HoverHandler {
        id: mouse
    }

    Item {
        id: playerControl
        Layout.fillHeight: true
        Layout.preferredWidth: mouse.hovered ? pc.width : 0
        clip: true

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }

        PlayerControl {
            id: pc
            pm: pm
            tl: tl
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignRight
        }
    }

    CoverImage {
        id: ci
        Layout.fillHeight: true
        Layout.preferredWidth: height
        cover: mm.cover
    }

    Item {
        id: lyricPairContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    Component {
        id: lyricPairComponent
        LyricPair {}
    }

    Component {
        id: titlePairComponent
        TitlePair {}
    }

    PlayerManager {
        id: pm

        onPlayerExited: function () {
            lv.updateCurrentPair([
                {
                    text: "Lyriks",
                    t0: 0,
                    t1: 0
                }
            ], [
                {
                    text: "暂无播放",
                    t0: 0,
                    t1: 0
                }
            ]);
            lv.updateTitlePair("Lyriks", "暂无播放");
        }
    }

    TimeLine {
        id: tl
        pm: pm
    }

    MetaManager {
        id: mm
        pm: pm

        onTrackChanged: function (title: string, artists: list<string>) {
            lv.updateTitlePair(title, artists.join(" / "));
            lv.updateCurrentPair([
                {
                    text: title,
                    t0: 0,
                    t1: 0
                }
            ], [
                {
                    text: artists.join(" / "),
                    t0: 0,
                    t1: 0
                }
            ]);
        }
    }

    LyricManager {
        id: lm
        mm: mm
        tl: tl

        onUpdateLyrics: function (primary: list<var>, secondary: list<var>) {
            lv.updateCurrentPair(primary, secondary);
        }
    }

    function updateTitlePair(primary: string, secondary: string) {
        if (titlePair) {
            titlePair.end();
        }
        titlePair = titlePairComponent.createObject(lyricPairContainer, {
            primaryText: primary,
            secondaryText: secondary
        });
        titlePair.hovered = Qt.binding(() => mouse.hovered);
    }

    function updateCurrentPair(primary: list<var>, secondary: list<var>) {
        if (currentPair) {
            currentPair.end();
        }
        currentPair = lyricPairComponent.createObject(lyricPairContainer, {
            primaryWords: primary,
            secondaryWords: secondary,
            tl: tl
        });
        currentPair.hovered = Qt.binding(() => mouse.hovered);
    }
}
