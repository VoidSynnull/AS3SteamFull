var isIFrameWrapperLeft = false;
var isIFrameWrapperRight = false;
var isSafari = false;

// if safari but not chrome
if (navigator.userAgent.toLowerCase().indexOf("safari") != -1) {
	if (navigator.userAgent.toLowerCase().indexOf("chrome") == -1) {
		isSafari = true;
	}
}

// Campaign scripts for tracking pixels and wrappers
var campaignVars = {};
campaignVars.prefix = '';
function setStaticPrefix(prefix)
{
    /* All uses of the prefix provide their own initial "/" */
    if (prefix.charAt(prefix.length-1) == '/') {
        prefix = prefix.substr(0, prefix.length-1);
    }
    campaignVars.prefix = prefix;
}

function getStaticPrefix()
{ 
    return campaignVars.prefix;
}

function getStaticHost()
{
	var staticHost = window.location.host;
	// if live site then replace www with static and use https
	if (staticHost.indexOf("www") != -1)
		staticHost = "https://static" + staticHost.substr(3);
	else // if maint or dev site, then insert static and use http
	{
		var dotPos = staticHost.indexOf(".")
		staticHost = "http://" + staticHost.substr(0,dotPos+1) + "static" + staticHost.substr(dotPos);
	}
	return staticHost;
}

function checkFirefoxVersion()
{
	// if firefox
	if(window.navigator.userAgent.toLowerCase().indexOf('firefox') > -1)
	{
		// get firefox regex match
		var match = window.navigator.userAgent.match(/Firefox\/([0-9]+)\./);
		// get version
		var version = match ? parseInt(match[1]) : 0;
		// if 64 or higher
		if (version >= 64)
		{
			return "disabled";
		}
		else
		{
			return "allowed";
		}
	}
	return "allowed";
}

function clickLeftWrapper()
{
	document.getElementById("flashContent").clickLeftWrapper();
}

function clickRightWrapper()
{
	document.getElementById("flashContent").clickRightWrapper();
}

function refreshWrapper(msCampaign)
{
 	if(typeof window.top.tyche !== 'undefined')
	{
		var path = "/";
		// check for campaign that has linked wrappers
		switch(msCampaign)
		{
			case "AmericanGirlQuest":
				path = "/1campaign";
				break;
			case "Croods2MMSQ":
				path = "/2campaign";
				break;
			case "SpiritRidingFreeVBB":
				path = "/3campaign";
				break;
			case "WolfWalkersMMSQ":
				path = "/4campaign";
				break;
		}
		if (path == "/")
		{
			if(typeof window.top.tyche.changePath !== 'undefined')
			{
				window.top.tyche.changePath(path);	
			} else {
				console.log("changePath not found!");
			}
			if(typeof window.top.tyche.triggerRefresh !== 'undefined')
			{
				window.top.tyche.triggerRefresh();
			} else {
				console.log("triggerRefresh not found!");
			}
		}
		else
		{
			//alert(msCampaign + "  " + path)
			if(typeof window.top.tyche.changePath !== 'undefined')
			{
				window.top.tyche.changePath(path);	
			} else {
				console.log("changePath not found!");
			}
		}
	}
}

function showWrapper(campaignName, click_URL, leftWrapper, rightWrapper)
{
	// wrapper paths look like "images/surroundX_Name.jpg"
	// iframe html5 wrapper paths look like "images/wrappers/surroundX_Name/wrapper.html"
	if (leftWrapper != "images/wrappers/as3_/wrapper.html")
	{
		document.getElementById("wrapper_left_link").style.display = "block";
		// if left wrapper is jpeg
		if (leftWrapper.indexOf(".jpg") != -1)
		{
			isIFrameWrapperLeft = false;
			document.getElementById("wrapper_left").style.display = "block";
			document.getElementById("wrapper_left_iframe").style.display = "none";
			document.getElementById("wrapper_left_image").src = getStaticHost() + "/" + leftWrapper;
		}
		else
		{
			isIFrameWrapperLeft = true;
			document.getElementById("wrapper_left").style.display = "none";
			document.getElementById("wrapper_left_iframe").style.display = "block";
			document.getElementById("wrapper_left_container").src = getStaticHost() + "/" + leftWrapper;
		}
	}
	else
	{
		document.getElementById("wrapper_left_link").style.display = "none";
		document.getElementById("wrapper_left_iframe").style.display = "none";
		document.getElementById("wrapper_left").style.display = "none";
	}
	
	if (rightWrapper != "images/wrappers/as3_/wrapper.html")
	{
		document.getElementById("wrapper_right_link").style.display = "block";
		// if right wrapper is jpeg
		if (rightWrapper.indexOf(".jpg") != -1)
		{
			isIFrameWrapperRight = false;
			document.getElementById("wrapper_right").style.display = "block";
			document.getElementById("wrapper_right_iframe").style.display = "none";
			document.getElementById("wrapper_right_image").src = getStaticHost() + "/" + rightWrapper;
		}
		else
		{
			isIFrameWrapperRight = true;
			document.getElementById("wrapper_right").style.display = "none";
			document.getElementById("wrapper_right_iframe").style.display = "block";
			document.getElementById("wrapper_right_container").src = getStaticHost() + "/" + rightWrapper;
		}
	}
	else
	{
		document.getElementById("wrapper_right_link").style.display = "none";
		document.getElementById("wrapper_right_iframe").style.display = "none";
		document.getElementById("wrapper_right").style.display = "none";
	}
}

function clearWrapper()
{
	// hide display
	// this prevents the old wrapper from flashing when displaying a new wrapper
	document.getElementById("wrapper_left_link").style.display = "none";
	document.getElementById("wrapper_right_link").style.display = "none";
	document.getElementById("wrapper_left_image" ).src = "";
	document.getElementById("wrapper_right_image").src = "";
	document.getElementById("wrapper_left").style.display = "none";
	document.getElementById("wrapper_right").style.display = "none";
	document.getElementById("wrapper_left_iframe").style.display = "none";
	document.getElementById("wrapper_right_iframe").style.display = "none";
	document.getElementById("wrapper_left_container").src = "";
	document.getElementById("wrapper_right_container").src = "";
}

function hideWrapper()
{
	document.getElementById("wrapper_left_link").style.display = "none";
	document.getElementById("wrapper_right_link").style.display = "none";
	document.getElementById("wrapper_left_iframe").style.display = "none";
	document.getElementById("wrapper_left").style.display = "none";
	document.getElementById("wrapper_right_iframe").style.display = "none";
	document.getElementById("wrapper_right").style.display = "none";
}

function unhideWrapper()
{
	document.getElementById("wrapper_left_link").style.display = "block";
	document.getElementById("wrapper_right_link").style.display = "block";
	if (isIFrameWrapperLeft)
		document.getElementById("wrapper_left_iframe").style.display = "block";
	else
		document.getElementById("wrapper_left").style.display = "block";
	if (isIFrameWrapperRight)
		document.getElementById("wrapper_right_iframe").style.display = "block";
	else
		document.getElementById("wrapper_right").style.display = "block";
}

// when tutorial completed (pass login name for transaction ID)
function tutorialCompleted(transactionID)
{
	sendTrackingPixel("http://a2g-secure.com/p.ashx?a=16442&e=992&t=poptropica");
}

// Client 1x1 pixel tracking for games and specialized ads that can't do their own tracking
// Can't call getURL on these directly from Flash due to security.
// Argument is full URL of a 1x1 image.  The image is never displayed, just loaded.
// This is not used. sendTrackingPixels is used for all cases now.
function sendTrackingPixel(URLtoTrigger)
{
	if (!window.dcpix) window.dcpix = new Array();
	var i = window.dcpix.length;
	window.dcpix[i] = new Image();
	window.dcpix[i].src = URLtoTrigger + "&popcb=" + Math.random();
}

// Sometimes we want to invoke more than one tracking pixel from the same page.
// IE 6 only performs the last getURL on a page.  Provide a way to track multiple
// pixels from a single javascript: URL.
// Argument is array of full URLs of 1x1 images.  The image is never displayed, just loaded.
function sendTrackingPixels(urls)
{
	for (var i = 0; i < urls.length; i++) {
		var URLtoTrigger = urls[i];
		// if moat ad
		if (URLtoTrigger.indexOf("moatad") != -1)
		{
			var moatScript = document.createElement("script");
			moatScript.type = "text/javascript";
			moatScript.src = URLtoTrigger;
			document.body.appendChild(moatScript);
		}
		// if no script for moat
		else if (URLtoTrigger.indexOf("pop://no.script?") == 0)
		{
			var moatNoScript = document.createElement("noscript");
			moatNoScript.className = URLtoTrigger.substring(16);
			document.body.appendChild(moatNoScript);
		}
		else
		{
			if (!window.dcpix) window.dcpix = new Array();
			var j = window.dcpix.length;
			window.dcpix[j] = new Image();
			window.dcpix[j].src = URLtoTrigger + "&popcb=" + Math.random();
		}
	}
}

// plays video for theater and exposes video player
function playTheaterVideo()
{
	document.getElementById("theaterVideo").style.display = "block";
	document.getElementById("theaterVideos").src = "/game/videos.html";
}

function closeTheaterVideo()
{
	document.getElementById("theaterVideos").src = "http://www.google.com";
	document.getElementById("theaterVideo").style.display = "none";
	document.getElementById("flashContent").closeTheaterVideo();
}

// Tracking pixel when registration is completed
function completedRegistration(transactionID)
{
	var iframeElement = document.createElement("iframe");
	iframeElement.src = "https://a2g-secure.com/p.ashx?o=18794&e=991&t=" + transactionID + "&popcb=" + Math.random();
	iframeElement.width = "1";
	iframeElement.height = "1";
	iframeElement.frameborder = "0";
	document.body.appendChild(iframeElement);

	sendTrackingPixel("https://server.cpmstar.com/action.aspx?advertiserid=6625&gif=1");
	sendTrackingPixel("https://reader215.go2cloud.org/aff_l?offer_id=170");
	sendTrackingPixel("https://reader215.go2cloud.org/aff_l?offer_id=94");
	sendTrackingPixel("https://tracking.casreader215.com/aff_l?offer_id=171");
	sendTrackingPixel("https://tracking.casreader215.com/aff_l?offer_id=96");
}

// show video overlay with campaign name, video URL, locked video flag, video controls flag
function showVideoOverlay(campaignName, url, locked, controls) {
	// show video overlay
	document.getElementById("videoOverlay").style.visibility = "visible";

	// show/hide close button based on locked
	if (locked)
		document.getElementById("video_close").style.visibility = "hidden";
	else
		document.getElementById("video_close").style.visibility = "visible";
	
	if (controls) {
		document.getElementById("progress_bar").style.visibility = "hidden";
		document.getElementById("video_bottom").style.visibility = "visible";
		document.getElementById("video_bottom").style.top = "1px";
		document.getElementById("video_bottom").style.left = "490px";
		document.getElementById("video_bottom").style.bottom = null;
	} else {
		document.getElementById("progress_bar").style.visibility = "visible";
		document.getElementById("video_bottom").style.visibility = "visible";
		document.getElementById("video_bottom").style.top = "1px";
		document.getElementById("video_bottom").style.left = "490px";
		document.getElementById("video_bottom").style.bottom = null;

	}
	
	// get video
	var popVideo = document.getElementById("popVideo");
	popVideo.controls = controls;
	
	// mute if safari
	var buttonState = "hidden";
	if (isSafari) {
		popVideo.muted = true;
		// show unmute button if not controls
		if (!controls) {
			buttonState = "visible";
		}
	}
	document.getElementById("video_unmute").style.visibility = buttonState;
	
	popVideo.src = url;
	// play video
	popVideo.play();
	
	// when video completes
	popVideo.onended = function() {
		// clear time update
		popVideo.ontimeupdate = null;
		// clear source
		popVideo.src = "";
		// reset progress bar
		document.getElementById("bar").width = 0;
		// hide close button
		document.getElementById("video_close").style.visibility = "hidden";
		// hide video bottom
		document.getElementById("video_bottom").style.visibility = "hidden";
		// hide video unmute button
		document.getElementById("video_unmute").style.visibility = "hidden";
		// hide video overlay
		document.getElementById("videoOverlay").style.visibility = "hidden";
		// notify game that video has ended
		document.getElementById("flashContent").videoComplete();
	};
	// if no controls then update our custom progress bar
	if (!controls) {
		// progress bar update
		popVideo.ontimeupdate = function()
		{
			document.getElementById("bar").width = popVideo.currentTime / popVideo.duration * neww;
		}
	} else {
		// if controls then track play/pause/seek
		popVideo.onplaying = function(){
			var seconds = popVideo.currentTime.toFixed(0);
			brainEventTracker.addEvent({
				event: 'VideoPlay', campaign: campaignName, cluster: 'VideoOverlay', scene: 'Flash', choice: seconds
			});
		}
		popVideo.onpause = function(){
			var seconds = popVideo.currentTime.toFixed(0);
			brainEventTracker.addEvent({
				event: 'VideoPause', campaign: campaignName, cluster: 'VideoOverlay', scene: 'Flash', choice: seconds
			});
		}
		popVideo.onseeked = function(){
			var seconds = popVideo.currentTime.toFixed(0);
			brainEventTracker.addEvent({
				event: 'VideoSkip', campaign: campaignName, cluster: 'VideoOverlay', scene: 'Flash', choice: seconds
			});		
		}

	}
}

function videoSponsor() {
	// notify game that sponsor button has been clicked
	document.getElementById("flashContent").videoSponsor();
}

function videoClose() {
	var popVideo = document.getElementById("popVideo");
	// clear source
	popVideo.src = "";
	// clear time update
	popVideo.ontimeupdate = null;
	// reset progress bar
	document.getElementById("bar").width = 0;
	// hide close button
	document.getElementById("video_close").style.visibility = "hidden";
	// hide video bottom panel
	document.getElementById("video_bottom").style.visibility = "hidden";
	// hide video unmute button
	document.getElementById("video_unmute").style.visibility = "hidden";
	// hide video overlay
	document.getElementById("videoOverlay").style.visibility = "hidden";
	// notify game that video has been closed
	document.getElementById("flashContent").videoClose();
}

function unmuteVideo() {
	if (isSafari) {
		var popVideo = document.getElementById("popVideo");
		popVideo.muted = false;
		document.getElementById("video_unmute").style.visibility = "hidden";
	}
}