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
                if (cover !== "" || retryCount >= 3 || givenUp) {
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
                                // 按时长最接近排序
                                if (lengthUs > 0) {
                                    resp.result.songs.sort((a, b) => Math.abs(a.dt * 1000 - lengthUs) - Math.abs(b.dt * 1000 - lengthUs));
                                }
                                // 找第一个作者匹配的曲目
                                for (let i = 0; i < resp.result.songs.length; i++) {
                                    const song = resp.result.songs[i];
                                    if (song.ar && song.ar.length > 0) {
                                        let songArtists = [];
                                        for (let j = 0; j < song.ar.length; j++) {
                                            songArtists.push(song.ar[j].name);
                                            if (song.ar[j].alias) {
                                                for (let k = 0; k < song.ar[j].alias.length; k++) {
                                                    songArtists.push(song.ar[j].alias[k]);
                                                }
                                            }
                                        }
                                        for (let j = 0; j < songArtists.length; j++) {
                                            if (artists.indexOf(songArtists[j]) !== -1) {
                                                cover = song.al?.picUrl ?? "";
                                                break;
                                            }
                                        }
                                    }
                                    if (cover) {
                                        break;
                                    }
                                }
                                if (!cover) {
                                    cover = resp.result.songs[0]?.al?.picUrl ?? "";
                                    if (!cover) {
                                        givenUp = true;
                                    }
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
