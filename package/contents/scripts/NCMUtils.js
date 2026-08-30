function matchNCMusic(resp, artists, lengthUs) {
    let selectedIndex = -1;
    // 按时长最接近排序
    if (lengthUs > 0) {
        resp.result.songs.sort((a, b) => Math.abs(a.dt * 1000 - lengthUs) - Math.abs(b.dt * 1000 - lengthUs));
    }
    // 找第一个作者匹配的曲目
    let normalizedArtists = artists.map(s => s.trim().toLowerCase());
    for (let i = 0; i < resp.result.songs.length; i++) {
        const song = resp.result.songs[i];
        if (song.ar && song.ar.length > 0) {
            let songArtists = [];
            for (let j = 0; j < song.ar.length; j++) {
                songArtists.push(song.ar[j].name.trim().toLowerCase());
                if (song.ar[j].alias) {
                    for (let k = 0; k < song.ar[j].alias.length; k++) {
                        songArtists.push(song.ar[j].alias[k].trim().toLowerCase());
                    }
                }
            }
            for (let j = 0; j < songArtists.length; j++) {
                if (normalizedArtists.indexOf(songArtists[j]) !== -1) {
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
    return selectedIndex;
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
