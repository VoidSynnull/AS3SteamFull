package com.poptropica.interfaces
{
	import flash.display.BitmapData;
	
	public interface INativeAppMethods {
	
		//// Custom URL invocation ////
	
		function get invokeURLArgs():Array;
	
		//// Camera Roll support ////
	
		function get canExportToCameraRoll():Boolean;
	
		function exportToCameraRoll(imageData:BitmapData, fileName:String = null, callback:Function = null, failure:Function = null):Boolean;
	
	}
}