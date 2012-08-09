// ==UserScript==
// @name		   Tweetbot instead of Twitter
// @description	   Open Tweetbot instead of loading Twitter.com
// @match		   http://twitter.com/
// @match		   https://twitter.com/
// @require		   http://userscripts.org/scripts/source/49700.user.js
// @require		   http://userscripts.org/scripts/source/50018.user.js
// @version		   0.0.2
// ==/UserScript==

function main() {

	window.location = "tweetbot:///";

}

main();
