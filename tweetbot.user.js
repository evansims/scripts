// ==UserScript==
// @name		   Replace Twitter.com with Tweetbot
// @description	   Open Tweetbot instead of loading Twitter.com
// @match		   http://twitter.com/*
// @match		   https://twitter.com/*
// @require		   http://userscripts.org/scripts/source/49700.user.js
// @require		   http://userscripts.org/scripts/source/50018.user.js
// @version		   0.0.3
// ==/UserScript==

function main() {

	window.addEventListener("load", function() {
		var tweetbot = document.createElement('iframe');
			tweetbot.src = 'tweetbot:///';

		document.body.appendChild(tweetbot);
	});

}

main();
