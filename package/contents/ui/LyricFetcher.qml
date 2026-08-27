import QtQuick

Item {
    id: lf
    visible: false

    signal startFetch(string title, list<string> artists, string player)
    signal fetchFinished(
        var lyrics,
        string title,
        list<string> artists,
        string player
    )

    onStartFetch: function(title, artists, player) {
        let job = fetchJob.createObject(lf)
        if (job == null) {
            console.log("Failed to create fetch job for " + title)
            fetchFinished([], title, artists, player)
        } else {
            job.title = title
            job.artists = artists
            job.player = player
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
            /* {
                t: double,
                text: string,
                trans: string,
            } */
            property var lyrics: []

            onTriggered: function() {
                if (lyrics.length > 0 || retryCount >= 3) {
                    running = false
                    fetchFinished(lyrics, title, artists, player)
                    destroy()
                    return
                }
                if (!requestFinished) return // 请求还没结束，等下一个循环
                requestFinished = false
                fetchLyrics(title, artists, player)
                retryCount += 1
            }

            function fetchLyrics(title, artists, player) {
                if (player.indexOf("splayer") !== -1) { // SPlayer 有自己的 API ，用不着上网查歌词
                    let xhr = new XMLHttpRequest()
                    xhr.timeout = 1000
                    xhr.open("GET", "http://127.0.0.1:14558/api/lyrics")
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            requestFinished = true
                            if (xhr.status === 200) {
                                const respLyrics = JSON.parse(xhr.responseText)["lyric"]
                                lyrics = []
                                for (let i = 0; i < respLyrics.length; i++) {
                                    let lyricLine = ""
                                    const words = respLyrics[i]["words"]
                                    for (let j = 0; j < words.length; j++) { // 暂时不处理逐字歌词，直接拼接
                                        lyricLine += words[j]["word"]
                                    }
                                    lyrics.push({
                                        t: respLyrics[i]["startTime"] * 1000,
                                        text: lyricLine,
                                        trans: respLyrics[i]["translatedLyric"],
                                    })
                                }
                            }
                        }
                    }
                    xhr.send()
                }
            }
        }
    }
}
