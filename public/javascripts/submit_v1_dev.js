(function(){
	alert("development bookmarklet!");
	var xhr;
	if (XMLHttpRequest)
	{
		try {
			xhr = new XMLHttpRequest();
		} catch(e){};
	}
	else if(ActiveXObject)
	{
		try {
			xhr = new ActiveXObject("Msxml2.XMLHTTP");
		} catch (e) {
			try {
				xhr = new ActiveXObject("Microsoft.XMLHTTP");
			} catch(e){};
		}
	}
	
	// Form request
	//
	
	// Send
	xhr.open('PUT', "http://localhost:3000/ping", true);
	
	// Show confirmation, like button
	//
})();