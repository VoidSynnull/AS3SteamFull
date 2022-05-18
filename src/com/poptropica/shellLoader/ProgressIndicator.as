package com.poptropica.shellLoader {

import flash.display.Sprite;

public class ProgressIndicator extends Sprite implements IShellLoaderIndicator {

	import flash.display.MovieClip;
	import flash.events.Event;

	// stage instances
	public var fluid:MovieClip;

	//// CONSTRUCTOR ////

	public function ProgressIndicator()
	{
		fluid.scaleX = 0.001;
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	//// ACCESSORS ////

	//// PUBLIC METHODS ////

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function onAddedToStage(e:Event):void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
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
		fluid.scaleX = newPercent/100;
	}

}

}
