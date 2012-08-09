// ==UserScript==
// @name           Replace Twitter.com with Tweetbot
// @description    Open Tweetbot instead of loading Twitter.com
// @match          http://twitter.com/*
// @match          https://twitter.com/*
// @require        http://userscripts.org/scripts/source/49700.user.js
// @require        http://userscripts.org/scripts/source/50018.user.js
// @version        0.0.4
// ==/UserScript==

function main() {

    window.addEventListener("load", function() {
        var tweetbot = document.createElement('iframe');
            tweetbot.src = 'tweetbot://';

        var path = location.pathname.substr(1);

        if(path.length) {
            tweetbot.src += path;
        } else {
            tweetbot.src += '/';
        }

        document.body.appendChild(tweetbot);
    });

}

main();
