(function(){
	
	// Instead, what we're going to do here is open a little iFrame that will ask you to sign in if you haven't yet

	// This way there's no sign up step!
	
	// Maybe even have a profile link in the header, if the user clicks it they're asked to sign in, but views aren't different for signed in/out users!
	
	var title = document.getElementsByTagName('title')[0].innerHTML;
	var src = "http://localhost:3000/bookmarklet_submit/?t=" + escape(title) + "&u=" + escape(window.location.href);
	
	var f = document.createElement('iframe');
	f.setAttribute('src', src);
	f.setAttribute('style', 'position:absolute;z-index:9999999;top:15px;right:15px;width:450px;height:600px;border:5px solid black;');
	document.body.appendChild(f);
})();