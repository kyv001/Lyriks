import "../scripts/NCMUtils.js" as NCMUtils
import QtQuick

Item {
    id: cf
    visible: false

    signal startFetch(string title, list<string> artists, string player, int lengthUs)
    signal fetchFinished(string cover, string title, list<string> artists, string player)

    onStartFetch: function (title, artists, player, lengthUs) {
        let job = fetchJob.createObject(cf);
        if (job == null) {
            console.log("Failed to create fetch job for " + title);
            fetchFinished("", title, artists, player);
        } else {
            job.title = title;
            job.artists = artists;
            job.player = player;
            job.lengthUs = lengthUs;
            job.running = true;
        }
    }

    Component {
        id: fetchJob

        Timer {
            interval: 250
            repeat: true

            property int retryCount: 0
            property bool requestFinished: true
            property string title: ""
            property list<string> artists: []
            property string player: ""
            property string cover: ""
            property string apiUrl: "https://ncm-api.prod.gbclstudio.cn/"
            property int lengthUs: 0
            property bool givenUp: false

            onTriggered: function () {
                if (!requestFinished)
                    // 请求还没结束，等下一个循环
                    return;
                if (cover !== "" || retryCount >= 3 || givenUp) {
                    running = false;
                    fetchFinished(cover, title, artists, player);
                    destroy();
                    return;
                }
                requestFinished = false;
                fetchCover(title, artists, player, lengthUs);
                retryCount += 1;
            }

            function fetchCover(title, artists, player, lengthUs) {
                let xhr = new XMLHttpRequest();
                xhr.open("GET", `${apiUrl}/cloudsearch?keywords=${encodeURIComponent(title + " " + artists.join(" "))}&limit=30`);
                xhr.onreadystatechange = function () {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        requestFinished = true;
                        if (xhr.status === 200) {
                            const resp = JSON.parse(xhr.responseText);
                            if (resp && resp.result && resp.result.songs && resp.result.songs.length > 0) {
                                let selectedIndex = NCMUtils.matchNCMusic(resp, artists, lengthUs);
                                cover = resp.result.songs[selectedIndex].al?.picUrl ?? "";
                                if (!cover) {
                                    givenUp = true;
                                }
                            }
                        }
                    }
                };
                xhr.send();
            }
        }
    }
}
