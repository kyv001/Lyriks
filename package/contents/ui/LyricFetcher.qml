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
                if (lyrics.length > 0 || retryCount >= 3 || givenUp) {
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
                                        t: respLyrics[i]["startTime"],
                                        words: words,
                                        trans: [
                                            {
                                                text: respLyrics[i]["translatedLyric"],
                                                t0: respLyrics[i]["startTime"],
                                                t1: respLyrics[i]["endTime"]
                                            }
                                        ]
                                    });
                                }
                            }
                        }
                    };
                    xhr.send();
                } else { // 不是 SPlayer，使用网络 API 查歌词
                    let xhr = new XMLHttpRequest();
                    xhr.timeout = 2000;

                    // 1. 搜索歌曲
                    xhr.open("GET", `${apiUrl}/cloudsearch?keywords=${encodeURIComponent(title + " " + artists.join(" "))}&limit=30`);
                    xhr.onreadystatechange = function () {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            // requestFinished = true; // 只有第一步完成了，不急着报告请求完毕
                            if (xhr.status === 200) {
                                const resp = JSON.parse(xhr.responseText);
                                if (resp && resp.result && resp.result.songs && resp.result.songs.length > 0) {
                                    let selectedIndex = -1;
                                    // 按时长最接近排序
                                    if (lengthUs > 0) {
                                        resp.result.songs.sort((a, b) => Math.abs(a.dt * 1000 - lengthUs) - Math.abs(b.dt * 1000 - lengthUs));
                                    }
                                    // 找第一个作者匹配的曲目
                                    for (let i = 0; i < resp.result.songs.length; i++) {
                                        const song = resp.result.songs[i];
                                        if (song.ar && song.ar.length > 0) {
                                            let songArtists = []
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
                                                    selectedIndex = i;
                                                    break;
                                                }
                                            }
                                        }
                                        if (selectedIndex !== -1) {
                                            break;
                                        }
                                    }
                                    if (selectedIndex === -1) {
                                        selectedIndex = 0;
                                    }
                                    // 2. 获取 ID 后获取逐字歌词
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
                                let origLyric = parseLyric(chosenLyric, duration);
                                // --- 翻译歌词 ---
                                const chosenTrans = resp.ytlrc ? resp.ytlrc.lyric : (resp.tlyric ? resp.tlyric.lyric : null);
                                let transLyric = [];
                                if (chosenTrans !== null) {
                                    transLyric = parseLyric(chosenTrans, duration);
                                }
                                lyrics = alignTrans(origLyric, transLyric);
                            }
                        }
                    }
                };
                xhr.send();
            }

            function parseLyric(rawLyric, duration) {
                let lyric = [];
                const lyricLines = rawLyric.split("\n").filter(line => line.trim().startsWith("[")).map(line => line.trim());
                /*
                Format A
                [16210,3460](16210,670,0)还(16880,410,0)没...
                 ~~~~1 ~~~2  ~~~~3 ~~4 5 ~6(...)
                1 歌词行显示开始时间戳（毫秒）
                2 歌词行显示总时长（毫秒）
                3 逐字显示开始时间戳（毫秒）
                4 逐字显示时长（毫秒）
                5 未知
                6 文字

                Format B
                [00:09.52] Give me ...
                 ~~1~~~~~2
                1 分钟
                2 秒
                */
                const lineTimeA = /^\[(\d+),(\d+)\](.*)/;
                const wordA = /\((\d+),(\d+),(\d+)\)([^|(]+)/g;
                const lineTimeB = /^\[(\d+):([\d\.]+)\](.*)/;
                for (let i = 0; i < lyricLines.length; i++) {
                    let words = [];
                    const rawLine = lyricLines[i];
                    if (lineTimeA.test(rawLine)) {
                        // i. 歌词行时间
                        const lineTimeMatch = rawLine.match(lineTimeA);
                        const lineStart = parseInt(lineTimeMatch[1]);
                        let wordMatch;
                        while ((wordMatch = wordA.exec(lineTimeMatch[3])) !== null) {
                            // ii. 单词时间
                            const wordText = wordMatch[4];
                            const wordT0 = parseInt(wordMatch[1]);
                            const wordT1 = wordT0 + parseInt(wordMatch[2]);
                            words.push({
                                text: wordText,
                                t0: wordT0,
                                t1: wordT1
                            });
                        }
                        lyric.push({
                            t: lineStart,
                            words: words
                        });
                    } else if (lineTimeB.test(rawLine)) {
                        // i. 歌词行时间
                        const lineTimeMatch = rawLine.match(lineTimeB);
                        const lineStart = (parseInt(lineTimeMatch[1]) * 60 + parseFloat(lineTimeMatch[2])) * 1000;
                        words.push({
                            text: lineTimeMatch[3],
                            t0: lineStart,
                            t1: null
                        });
                        lyric.push({
                            t: lineStart,
                            words: words
                        });
                    }
                }
                // 解决 t1: null
                for (let i = 0; i < lyric.length; i++) {
                    for (let j = 0; j < lyric[i].words.length; j++) {
                        if (lyric[i].words[j].t1 === null) {
                            if (j < lyric[i].words.length - 1) {
                                // 同一行有下一词：取下一词起始时间为结束时间
                                lyric[i].words[j].t1 = lyric[i].words[j + 1].t0;
                            } else if (i < lyric.length - 1) {
                                // 同一行无下一词：取下一行起始时间为结束时间
                                lyric[i].words[j].t1 = lyric[i + 1].t;
                            } else {
                                // 最后一行：取总时长为结束时间
                                lyric[i].words[j].t1 = duration;
                            }
                        }
                    }
                }
                return lyric;
            }

            function alignTrans(origLyric, transLyric) {
                let lyrics = [];
                for (let i = 0; i < origLyric.length; i++) {
                    lyrics.push({
                        t: origLyric[i].t,
                        words: origLyric[i].words,
                        trans: []
                    });
                    let transT = -1;
                    for (let j = 0; j < transLyric.length; j++) {
                        if (Math.abs(transLyric[j].t - lyrics[i].t) < Math.min(Math.abs(lyrics[i].t - transT), 1000)) {
                            lyrics[i].trans = transLyric[j].words;
                            transT = transLyric[j].t;
                        }
                    }
                }
                return lyrics;
            }
        }
    }
}
