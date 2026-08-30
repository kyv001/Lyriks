import QtQuick
import "../scripts/NCMUtils.js" as NCMUtils

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
            job.running = true;
        }
    }

    Component {
        id: fetchJob

        Timer {
            interval: 250
            running: false
            repeat: true

            property int retryCount: 0
            property bool requestFinished: true
            property string title: ""
            property list<string> artists: []
            property string player: ""
            property int lengthUs: 0
            /* {
                t: double, // 毫秒
                words: list<{
                    text: string,
                    t0: double, // 毫秒
                    t1: double, // 毫秒
                }>,
                trans: list<{
                    text: string,
                    t0: double, // 毫秒
                    t1: double, // 毫秒
                }>
            } */
            property var lyrics: []
            property string apiUrl: "https://ncm-api.prod.gbclstudio.cn/"
            property bool givenUp: false

            onTriggered: function () {
                if (!requestFinished)
                    // 请求还没结束，等下一个循环
                    return;
                if (lyrics.length > 0 || retryCount >= 3 || givenUp) {
                    running = false;
                    fetchFinished(lyrics, title, artists, player);
                    destroy();
                    return;
                }
                requestFinished = false;
                fetchLyrics(title, artists, player);
                retryCount += 1;
            }

            function fetchLyrics(title, artists, player) {
                if (player.indexOf("splayer") !== -1) { // SPlayer 有自己的 API ，用不着上网查歌词
                    let xhr = new XMLHttpRequest();
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
                                    let trans = [];
                                    if (respLyrics[i]["translatedLyric"]) {
                                        trans.push({
                                            text: respLyrics[i]["translatedLyric"],
                                            t0: respLyrics[i]["startTime"],
                                            t1: respLyrics[i]["endTime"]
                                        });
                                    }
                                    lyrics.push({
                                        t: respLyrics[i]["startTime"],
                                        words: words,
                                        trans: trans
                                    });
                                }
                            }
                        }
                    };
                    xhr.send();
                } else { // 不是 SPlayer，使用网络 API 查歌词
                    let xhr = new XMLHttpRequest();
                    // 1. 搜索歌曲
                    xhr.open("GET", `${apiUrl}/cloudsearch?keywords=${encodeURIComponent(title + " " + artists.join(" "))}&limit=30`);
                    xhr.onreadystatechange = function () {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            // requestFinished = true; // 只有第一步完成了，不急着报告请求完毕
                            if (xhr.status === 200) {
                                const resp = JSON.parse(xhr.responseText);
                                if (resp && resp.result && resp.result.songs && resp.result.songs.length > 0) {
                                    let selectedIndex = NCMUtils.matchNCMusic(resp, artists, lengthUs);
                                    fetchLyricsById(resp.result.songs[selectedIndex].id, resp.result.songs[selectedIndex].dt);
                                } else {
                                    requestFinished = true;
                                    givenUp = true;
                                }
                            } else {
                                requestFinished = true;
                            }
                        }
                    };
                    xhr.send();
                }
            }

            // 写在外面防止嵌套爆炸
            function fetchLyricsById(id: string, duration: int) {
                let xhr = new XMLHttpRequest();
                xhr.timeout = 2000;
                xhr.open("GET", `${apiUrl}/lyric/new?id=${id}`);
                xhr.onreadystatechange = function () {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        requestFinished = true; // 第二次请求结束才是真的请求完毕
                        if (xhr.status === 200) {
                            const resp = JSON.parse(xhr.responseText);
                            if (resp) {
                                // --- 原文歌词 ---
                                const chosenLyric = resp.yrc ? resp.yrc.lyric : (resp.lrc ? resp.lrc.lyric : null);
                                if (chosenLyric === null) {
                                    givenUp = true;
                                    return;
                                }
                                let origLyric = NCMUtils.parseLyric(chosenLyric, duration);
                                // --- 翻译歌词 ---
                                const chosenTrans = resp.ytlrc ? resp.ytlrc.lyric : (resp.tlyric ? resp.tlyric.lyric : null);
                                let transLyric = [];
                                if (chosenTrans !== null) {
                                    transLyric = NCMUtils.parseLyric(chosenTrans, duration);
                                }
                                lyrics = NCMUtils.alignTrans(origLyric, transLyric);
                            }
                        }
                    }
                };
                xhr.send();
            }
        }
    }
}
