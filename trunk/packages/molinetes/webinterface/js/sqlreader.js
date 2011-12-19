var ajaxObject = function (url, callbackFunction) {
  var that=this;
	var urlCall = url;

	this.updating = false;
	this.readyState = 0;
	this.status = 0;

	this.onEventFunctions = Array();
	this.responseText = new String();
	this.statusText = new String();
	this.responseXML = new String();

//	this.statePopUp = new loadingDataPopUp("Uninitialized");

  this.abort = function() {
		if (that.updating) {
			that.updating=false;
      that.AJAX.abort();
      that.AJAX=null;
		}  
	} 
	this.update = function(passData,postMethod) {
		if (that.updating) {
			return false; 
		}
    that.AJAX = null;
		if (window.XMLHttpRequest) {
			that.AJAX=new XMLHttpRequest();
		} else {
			that.AJAX=new ActiveXObject("Microsoft.XMLHTTP");
		}
		if (that.AJAX==null) {
			return false;
		} else {
			that.AJAX.onreadystatechange = function() {
				that.readyState = that.AJAX.readyState;
				if (that.AJAX.readyState==4) {
					that.updating=false;
					that.responseText = that.AJAX.responseText
					that.status = that.AJAX.status;
					that.statusText = that.AJAX.statusText;
					that.responseXML = that.AJAX.responseXML;
					that.callback(that.AJAX.responseText,that.AJAX.status,that.AJAX.responseXML);
					that.AJAX=null;
				}
				that.onStateChanged(that.readyState);
			}
			that.updating = new Date();
			if (/post/i.test(postMethod)) {
				var uri=urlCall+'?'+that.updating.getTime();
        that.AJAX.open("POST", uri, true);
        that.AJAX.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        that.AJAX.setRequestHeader("Content-Length", passData.length);
        that.AJAX.send(passData);
			} else {
				var uri=urlCall+'?'+passData+'&timestamp='+(that.updating.getTime());
				that.AJAX.open("GET", uri, true);
				that.AJAX.send(null);
			}
			return true;
		}
	}  
	this.onStateChanged = function (state) {
		for (obj=0;obj<this.onEventFunctions.length;obj++){
			if(state == 1){
				this.onEventFunctions[obj].loadingData();
			} else if (state == 2){
				this.onEventFunctions[obj].loadedData();
			} else if (state == 3){
				this.onEventFunctions[obj].interactiveData();
			} else if (state == 4){
				this.onEventFunctions[obj].completeData();
			}
		}
	};
	this.callback = callbackFunction || function () {};
}
var loadingDataPopUp = function (msg){
	var mymsg = (msg) ? msg : "Loading Data";
	var waitdiv = document.createElement("div");
	waitdiv.style.position="absolute";
	waitdiv.style.minWidth="126px";
	waitdiv.style.minHeight="22px";
	waitdiv.style.backgroundImage="url('../../../images/loading.gif')";
	waitdiv.style.backgroundRepeat="no-repeat";
	waitdiv.style.top="0";
	waitdiv.style.left="0";
	waitdiv.style.border="1px solid green";
	waitdiv.style.color="red";
	waitdiv.style.fontSize="11px";
	waitdiv.style.textAlign="center";
	waitdiv.innerHTML="<p style='margin:4px 0'>"+mymsg+"</p>";
	waitdiv.style.display = "none";
	return waitdiv;
}


function readfile_new(callObj,rstObjName, script, qry, method) {
	var mytime = new Date();
	var currTime = mytime.getTime();
	if (callObj.timer) clearTimeout(callObj.timer);
	if (callObj.value.length == 0) {
		contenedor = document.getElementById(rstObjName);
		contenedor.innerHTML = "";
		return;
	}
	callObj.timer = setTimeout("readfile('"+rstObjName+"','"+script+"','"+qry+"','"+method+"')",1500);
}

function readfile(contenedor, script, qry, method) {
	var waitdiv = loadingDataPopUp();
	cont = document.getElementById(contenedor);
	cont.appendChild(waitdiv);

	mytime = new Date();
	var met = method;
	var pars = qry + "&content=" + contenedor + "&script=" + script + "&time=" + (mytime.getTime());
	var opciones = {
		method: met,
		parameters: pars,
	// función a llamar cuando reciba la respuesta
		onSuccess: function(t) {
			try
			{
			//Run some code here
				var datos = eval('(' + t.responseText + ')');
				procesar(datos);
			}
			catch(err)
			{
				//Handle errors here
				contenedor = document.getElementById(contenedor);
				contenedor.innerHTML = t.responseText;
			}
			waitdiv.style.display = "block";
		}
	}
//	new Ajax.Request(script, opciones);
	waitdiv.style.display = "block";
	new Ajax.Request(script, opciones);
}

function readfile_mio(contenedor, script, qry, method) {
	var mytime = new Date();
	var callbackFn = eval("procesador");

	var myData = new ajaxObject(script, callbackFn);
	var pars = qry + "&content=" + contenedor + "&script=" + script + "&time=" + (mytime.getTime());
	myData.update(pars,"GET");
}

function procesador(text,status) {
	if (status == 200){
		var datos = eval('(' + text + ')');
//		var datos = eval( text );
//		var datos = jsonParse(text);
// guardo el div donde voy a escribir los datos en una variable
		contenedor = document.getElementById(datos.content);
//		contenedor = document.getElementById("pepe");
		var texto = "&nbsp;&nbsp;&nbsp;Tiempo mySQL qry: "+(datos.time*1000)+"ms / "+datos.total+" regs&nbsp;&nbsp;Showing regs : "+((datos.curpage-1)*datos.cnt)+"/"+(((datos.curpage)*datos.cnt) > datos.total ? datos.total : ((datos.curpage)*datos.cnt))+"&nbsp;pagina : "+datos.curpage+" de "+datos.pages+"<BR>";
		texto += "<div style='height:300px; width:100%; overflow: scroll;'>";
		texto += "<table border=\"1\" width=\"100%\">";
		for (var i=0; i < datos.regs.length; i++) {
//		for (var i=0; i < datos.length; i++) {
			dato = datos.regs[i];
			texto += "<TR>";
			for (n in dato) {
				texto += "<TD>" + dato[n] + "</TD>";
			}
			texto += "</TR>";
		}
		texto += "</table></div>";

		if (datos.first) {
			texto += "<input type=\"button\" ID=\"firstBoton\" value=\"First\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.first+"','get');\" >";
		}
		if (datos.prev) {
			texto += "<input type=\"button\" ID=\"prevBoton\" value=\"Previus\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.prev+"','get');\" >";
		}
		if (datos.next) {
			texto += "<input type=\"button\" ID=\"nextBoton\" value=\"Next\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.next+"','get');\" >";
		}
		if (datos.last) {
			texto += "<input type=\"button\" ID=\"lastBoton\" value=\"Last\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.last+"','get');\" >";
		}
//	texto += "&nbsp;&nbsp;&nbsp;"+datos.time+"&nbsp;&nbsp;&nbsp;pagina : "+datos.curpage+" de "+datos.pages;
	//Escribo el texto que formé en el div que corresponde
		contenedor.innerHTML = texto;
	}else{
		contenedor.innerHTML = status;
	}
}

function procesar(datos) {
// guardo el div donde voy a escribir los datos en una variable
	contenedor = document.getElementById(datos.content);
	var texto = "&nbsp;&nbsp;&nbsp;Tiempo mySQL qry: "+(datos.time*1000)+"ms / "+datos.total+" regs&nbsp;&nbsp;Showing regs : "+((datos.curpage-1)*datos.cnt)+"/"+(((datos.curpage)*datos.cnt) > datos.total ? datos.total : ((datos.curpage)*datos.cnt))+"&nbsp;pagina : "+datos.curpage+" de "+datos.pages+"<BR>";
	texto += "<div style='height:300px; width:100%; overflow: scroll;'>";
	texto += "<table border=\"1\" width=\"100%\">";
	for (var i=0; i < datos.regs.length; i++) {
		dato = datos.regs[i];
		texto += "<TR>";
		for (n in dato) {
			texto += "<TD>" + dato[n] + "</TD>";
		}
		texto += "</TR>";
	}
	texto += "</table></div>";

	if (datos.first) {
		texto += "<input type=\"button\" ID=\"firstBoton\" value=\"First\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.first+"','get');\" >";
		}
	if (datos.prev) {
		texto += "<input type=\"button\" ID=\"prevBoton\" value=\"Previus\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.prev+"','get');\" >";
		}
	if (datos.next) {
		texto += "<input type=\"button\" ID=\"nextBoton\" value=\"Next\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.next+"','get');\" >";
		}
	if (datos.last) {
		texto += "<input type=\"button\" ID=\"lastBoton\" value=\"Last\" onClick=\"readfile('"+datos.content+"','"+datos.script+"','"+datos.last+"','get');\" >";
		}
//	texto += "&nbsp;&nbsp;&nbsp;"+datos.time+"&nbsp;&nbsp;&nbsp;pagina : "+datos.curpage+" de "+datos.pages;
	//Escribo el texto que formé en el div que corresponde
	contenedor.innerHTML = texto;
}
