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
        }
    }

    Component {
        id: fetchJob

        Timer {
            interval: 250
            running: true
            repeat: true

            property int retryCount: 0
            property bool requestFinished: true
            property string title: ""
            property list<string> artists: []
            property string player: ""
            property string cover: ""
            property string apiUrl: "https://ncm-api.prod.gbclstudio.cn/"
            property int lengthUs: 0

            onTriggered: function () {
                if (cover !== "" || retryCount >= 3) {
                    running = false;
                    fetchFinished(cover, title, artists, player);
                    destroy();
                    return;
                }
                if (!requestFinished)
                    // 请求还没结束，等下一个循环
                    return;
                requestFinished = false;
                fetchCover(title, artists, player, lengthUs);
                retryCount += 1;
            }

            function fetchCover(title, artists, player, lengthUs) {
                let xhr = new XMLHttpRequest();
                xhr.timeout = 1000;
                xhr.open("GET", `${apiUrl}/cloudsearch?keywords=${encodeURIComponent(title + " " + artists.join(" "))}&limit=30`);
                xhr.onreadystatechange = function () {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        requestFinished = true;
                        if (xhr.status === 200) {
                            const resp = JSON.parse(xhr.responseText);
                            if (resp && resp.result && resp.result.songs && resp.result.songs.length > 0) {
                                if (lengthUs > 0) {
                                    resp.result.songs.sort((a, b) => Math.abs(a.dt * 1000 - lengthUs) - Math.abs(b.dt * 1000 - lengthUs));
                                }
                                cover = resp.result.songs[0].al.picUrl;
                            }
                        }
                    }
                };
                xhr.send();
            }
        }
    }
}
