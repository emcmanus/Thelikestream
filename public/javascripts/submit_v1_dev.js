(function(){
	
	
	// Create our context
	var e = document.createElement('div');
	e.style.position = "fixed";
	e.style.zIndex = 99999;
	e.style.top="15px";
	e.style.right="15px";
	e.style.width="450px";
	e.style.height="600px";
	e.style.border="5px solid black";
	e.style.backgroundColor="white";
	document.body.insertBefore(e, document.body.firstChild);
	
	e.innerHTML = "hello";
	
	
	
	
	/*
	var title = document.getElementsByTagName('title')[0].innerHTML;
	var src = "http://localhost:3000/bookmarklet_submit/?t=" + escape(title) + "&u=" + escape(window.location.href);
	
	// Attach Remote Source
	var e = document.createElement('iframe');
	e.setAttribute('src', src);
	e.style.position = "absolute";
	e.style.zIndex = 99999;
	e.style.top="15px";
	e.style.right="15px";
	e.style.width="450px";
	e.style.height="600px";
	e.style.border="5px solid black";
	document.body.insertBefore(e, document.body.firstElementChild);*/
})();