import QtQuick

Item {
    id: lf
    visible: false

    signal startFetch(string title, list<string> artists, string player)
    signal fetchFinished(
        string cover,
        string title,
        list<string> artists,
        string player
    )

    onStartFetch: function(title, artists, player) {
        let job = fetchJob.createObject(lf)
        if (job == null) {
            console.log("Failed to create fetch job for " + title)
            fetchFinished("", title, artists, player)
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
            property string cover: ""
            property string apiUrl: "https://ncm-api.prod.gbclstudio.cn/"

            onTriggered: function() {
                if (cover !== "" || retryCount >= 3) {
                    running = false
                    fetchFinished(cover, title, artists, player)
                    destroy()
                    return
                }
                if (!requestFinished) return // 请求还没结束，等下一个循环
                requestFinished = false
                fetchCover(title, artists, player)
                retryCount += 1
            }

            function fetchCover(title, artists, player) {
                let xhr = new XMLHttpRequest()
                xhr.timeout = 1000
                xhr.open("GET", apiUrl + "/cloudsearch?keywords=" + encodeURIComponent(title) + "&limit=1")
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        requestFinished = true
                        if (xhr.status === 200) {
                            const resp = JSON.parse(xhr.responseText)
                            if (resp && resp.result && resp.result.songs && resp.result.songs.length > 0) {
                                cover = resp.result.songs[0].al.picUrl
                            }
                        }
                    }
                }
                xhr.send()
            }
        }
    }
}
