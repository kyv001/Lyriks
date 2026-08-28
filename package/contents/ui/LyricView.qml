import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: lv
    Layout.minimumWidth: 10 * Kirigami.Units.gridUnit
    Layout.minimumHeight: 2 * Kirigami.Units.gridUnit
    Layout.preferredWidth: 20 * Kirigami.Units.gridUnit
    clip: true

    property LyricPair titlePair: null
    property LyricPair currentPair: null

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

    PlayerManager {
        id: pm
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
            lv.updateCurrentPair(title, artists.join(" / "));
        }
    }

    LyricManager {
        id: lm
        mm: mm
        tl: tl

        onUpdateLyrics: function (primary: string, secondary: string) {
            lv.updateCurrentPair(primary, secondary);
        }
    }

    function updateTitlePair(primary: string, secondary: string) {
        if (titlePair) {
            titlePair.end();
        }
        titlePair = lyricPairComponent.createObject(lyricPairContainer, {
            primaryText: primary,
            secondaryText: secondary,
            tl: tl
        });
        titlePair.visible = false;
    }

    function updateCurrentPair(primary: string, secondary: string) {
        if (currentPair) {
            currentPair.end();
        }
        currentPair = lyricPairComponent.createObject(lyricPairContainer, {
            primaryText: primary,
            secondaryText: secondary,
            tl: tl
        });
    }
}
