package com.poptropica.shellLoader {

import flash.display.Sprite;

public class SWFIndicator extends Sprite implements IShellLoaderIndicator {

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	private var CONFIG_FILE_NAME:String = 'shellLoaderConfig.xml';

	private var configLoader:URLLoader = new URLLoader();
	private var swfLoader:Loader = new Loader();

	// stage instances

	//// CONSTRUCTOR ////

	public function SWFIndicator()
	{
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	//// ACCESSORS ////

	//// PUBLIC METHODS ////

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function onAddedToStage(e:Event):void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		configLoader.addEventListener(Event.COMPLETE, onConfigLoaded);
		configLoader.load(new URLRequest(CONFIG_FILE_NAME));
	}

	private function onConfigLoaded(e:Event):void {
		e.currentTarget.removeEventListener(Event.COMPLETE, onConfigLoaded);
		trace("data loaded: " + e.target.data);
		var configData:XML = XML(configLoader.data);
		var swfURL:String = configData.url.(@id == 'animationPath')[0];
		var animationRequest:URLRequest = new URLRequest(swfURL);
		loadAnimation(animationRequest);
	}

	private function loadAnimation(animationRequest:URLRequest):void {
		swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadingComplete);
		swfLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
//        swfLoader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus);
		swfLoader.load(animationRequest);
	}

	private function onLoadingComplete(e:Event):void {
		e.currentTarget.removeEventListener(Event.COMPLETE, onLoadingComplete);
		e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
		addChild(swfLoader);
	}

	private function onLoadingError(e:IOErrorEvent):void {
		e.currentTarget.removeEventListener(Event.COMPLETE, onLoadingComplete);
		e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
		trace("loading error:", e);
	}

	private function onHTTPStatus(e:HTTPStatusEvent):void {
		trace("STATUS!", e);
	}

	private function randInRange(min:Number, max:Number):int {
		return Math.floor(min) + Math.floor(Math.random() * (max + 1 - min));
	}

	//// INTERFACE IMPLEMENTATIONS ////

	// IShellLoaderIndicator

	public function start():void
	{
	}

	public function stop():void
	{
	}

	public function showPercent(newPercent:Number):void
	{
	
	}

}

}
