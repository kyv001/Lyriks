import QtQuick

Item {
    id: lf
    visible: false

    signal startFetch(string title, list<string> artists, string player, int lengthUs)
    signal fetchFinished(var lyrics, string title, list<string> artists, string player)

    onStartFetch: function (title, artists, player, lengthUs) {
        let job = fetchJob.createObject(lf);
        if (job == null) {
            console.log("Failed to create fetch job for " + title);
            fetchFinished([], title, artists, player);
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
            property int lengthUs: 0
            /* {
                t: double,
                words: list<{
                    text: string,
                    t0: double,
                    t1: double,
                }>,
                trans: string,
            } */
            property var lyrics: []

            onTriggered: function () {
                if (lyrics.length > 0 || retryCount >= 3) {
                    running = false;
                    fetchFinished(lyrics, title, artists, player);
                    destroy();
                    return;
                }
                if (!requestFinished)
                    // 请求还没结束，等下一个循环
                    return;
                requestFinished = false;
                fetchLyrics(title, artists, player);
                retryCount += 1;
            }

            function fetchLyrics(title, artists, player) {
                if (player.indexOf("splayer") !== -1) { // SPlayer 有自己的 API ，用不着上网查歌词
                    let xhr = new XMLHttpRequest();
                    xhr.timeout = 1000;
                    xhr.open("GET", "http://127.0.0.1:14558/api/lyrics");
                    xhr.onreadystatechange = function () {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            requestFinished = true;
                            if (xhr.status === 200) {
                                const respLyrics = JSON.parse(xhr.responseText)["lyric"];
                                lyrics = [];
                                for (let i = 0; i < respLyrics.length; i++) {
                                    let words = [];
                                    const respWords = respLyrics[i]["words"];
                                    for (let j = 0; j < respWords.length; j++) {
                                        words.push({
                                            text: respWords[j]["word"],
                                            t0: respWords[j]["startTime"],
                                            t1: respWords[j]["endTime"]
                                        });
                                    }
                                    lyrics.push({
                                        t: respLyrics[i]["startTime"] * 1000,
                                        words: words,
                                        trans: respLyrics[i]["translatedLyric"]
                                    });
                                }
                            }
                        }
                    };
                    xhr.send();
                }
            }
        }
    }
}
