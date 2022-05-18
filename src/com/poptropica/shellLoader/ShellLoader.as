package com.poptropica.shellLoader {

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.external.ExternalInterface;
import flash.net.URLRequest;

public class ShellLoader extends Sprite {


	private var loadingIndicator:IShellLoaderIndicator;
	private var gameLoader:Loader;
	private var indicators:Vector.<IShellLoaderIndicator>;
	private static var _params:Object;
	
	public static function get params():Object
	{
		return _params;
	}

	//// CONSTRUCTOR ////

	public function ShellLoader(indicator:IShellLoaderIndicator=null)
	{
		var swfURL:String = '';
		_params = root.loaderInfo.parameters;
		if (_params.hasOwnProperty('shellURL')) {
			swfURL = _params["shellURL"];
		}
		gameLoader = new Loader();
		gameLoader.name = "gameloaderfromshellloader";
		gameLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadingProgress);
		gameLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadingComplete);
		gameLoader.load(new URLRequest(swfURL));
		
		addIndicator(new SWFIndicator());
		addIndicator(new ProgressIndicator());
		for (var i:int=0; i<indicators.length; i++) {
			addChild(indicators[i] as DisplayObject);
			indicators[i].start();
		}
	}

	//// ACCESSORS ////

// 	public function set indicator(newIndicator:IShellLoaderIndicator):void
// 	{
// 		loadingIndicator = newIndicator;
// 	}

	//// PUBLIC METHODS ////

	public function addIndicator(newIndicator:IShellLoaderIndicator):void
	{
		if (!indicators) {
			indicators = new <IShellLoaderIndicator>[];
		}
		indicators.push(newIndicator);
	}

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function onLoadingProgress(e:ProgressEvent):void
	{
		var bytesToLoad:int = e.bytesTotal - e.bytesLoaded;
		var fractionLoaded:Number = e.bytesLoaded/e.bytesTotal;
//		var newAlpha:Number = 1.0 - fractionLoaded;
//		(loadingIndicator as Sprite).alpha = newAlpha;
		for (var i:int=0; i<indicators.length; i++) {
			indicators[i].showPercent(100 * fractionLoaded);
		}
	}

	private function onLoadingComplete(e:Event):void
	{
		e.currentTarget.removeEventListener(ProgressEvent.PROGRESS, onLoadingProgress);
		e.currentTarget.removeEventListener(Event.COMPLETE, onLoadingComplete);
		
		for (var i:int=0; i<indicators.length; i++) 
		{
			removeChild(indicators[i] as DisplayObject);
		}
		indicators = null;
		
		trace("root: " + root.name + " this:" + name + " game loader:" + gameLoader.name);
		
		addChild(gameLoader);
	}
	

}

}
