import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: lv
    Layout.minimumWidth: 10 * Kirigami.Units.gridUnit
    Layout.minimumHeight: 2 * Kirigami.Units.gridUnit
    Layout.preferredWidth: 20 * Kirigami.Units.gridUnit
    clip: true

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

        onTrackChanged: function(title: string, artists: list<string>) {
            lv.updateCurrentPair(title, artists.join(" / "))
        }
    }

    LyricManager {
        id: lm
        mm: mm
        tl: tl

        onUpdateLyrics: function(primary: string, secondary: string) {
            lv.updateCurrentPair(primary, secondary)
        }
    }

    function updateCurrentPair(primary: string, secondary: string) {
        if (currentPair) {
            currentPair.end()
        }
        currentPair = lyricPairComponent.createObject(lyricPairContainer, { primaryText: primary, secondaryText: secondary })
    }
}
