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
    property bool idle: false

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

        onPlayerExited: lv.clear()
    }

    TimeLine {
        id: tl
        pm: pm
    }

    MetaManager {
        id: mm
        pm: pm

        onTrackChanged: function (title: string, artists: list<string>) {
            let artistsString = artists.length > 0 ? artists.join(" / ") : "未知艺术家";
            lv.updateTitlePair(title, artistsString);
            lv.updateCurrentPair([
                {
                    text: title,
                    t0: 0,
                    t1: 0
                }
            ], [
                {
                    text: artistsString,
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

        onUpdateLyrics: function (primary: list<var>, secondary: list<var>, isTranslated: bool) {
            lv.updateCurrentPair(primary, secondary, isTranslated);
        }
    }

    Component.onCompleted: clear()

    function clear() {
        if (idle)
            return;
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
        idle = true;
    }

    function updateTitlePair(primary, secondary) {
        idle = false;
        if (titlePair) {
            titlePair.end();
        }
        titlePair = titlePairComponent.createObject(lyricPairContainer, {
            primaryText: primary,
            secondaryText: secondary
        });
        titlePair.hovered = Qt.binding(() => mouse.hovered);
    }

    function updateCurrentPair(primary, secondary, isTranslated = false) {
        idle = false;
        if (currentPair) {
            currentPair.end();
        }
        currentPair = lyricPairComponent.createObject(lyricPairContainer, {
            primaryWords: primary,
            secondaryWords: secondary,
            tl: tl,
            isTranslated: isTranslated,
            isPreviewed: currentPair !== null && !currentPair.isTranslated
        });
        currentPair.hovered = Qt.binding(() => mouse.hovered);
    }
}
