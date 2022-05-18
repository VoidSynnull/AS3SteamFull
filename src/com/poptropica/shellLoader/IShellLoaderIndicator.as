package com.poptropica.shellLoader {

public interface IShellLoaderIndicator {

	function start():void;
	function stop():void;
	function showPercent(percentValue:Number):void;	// percentValue 0.0–1.0 inclusive

}

}
