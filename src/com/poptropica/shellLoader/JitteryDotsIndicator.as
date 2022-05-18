package com.poptropica.shellLoader {

import flash.display.Sprite;

public class JitteryDotsIndicator extends Sprite implements IShellLoaderIndicator {

	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;

	public static const TICK_INTERVAL:uint	= 50;

	private var dots:Vector.<MovieClip> = new <MovieClip>[];
	private var tickTimer:Timer;
	private var dotBounds:Rectangle;

	// stage instances
	public var redDot:MovieClip;
	public var greenDot:MovieClip;
	public var blueDot:MovieClip;

	//// CONSTRUCTOR ////

	public function JitteryDotsIndicator()
	{
		redDot.visible = greenDot.visible = blueDot.visible = false;
		addDot(redDot);
		addDot(greenDot);
		addDot(blueDot);
		tickTimer = new Timer(TICK_INTERVAL);
		tickTimer.addEventListener(TimerEvent.TIMER, onTick);
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	//// ACCESSORS ////

	//// PUBLIC METHODS ////

	public function addDot(anotherDot:MovieClip):void
	{
		dots.push(anotherDot);
	}

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function onTick(e:TimerEvent):void {
		for (var i:int=0; i<dots.length; i++) {
			moveDot(dots[i]);
		}
	}

	private function moveDot(theDot:MovieClip, makeVisible:Boolean=false):void {
		if (makeVisible) {
			theDot.visible = true;
		}
		theDot.x = randInRange(dotBounds.left, dotBounds.right);
		theDot.y = randInRange(dotBounds.top, dotBounds.bottom);
	}

	private function onAddedToStage(e:Event):void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		dotBounds = new Rectangle(0,0, stage.stageWidth, stage.stageHeight);
		dotBounds.inflate(redDot.width/-2, redDot.height/-2);
	}

	private function randInRange(min:Number, max:Number):int {
		return Math.floor(min) + Math.floor(Math.random() * (max + 1 - min));
	}

	//// INTERFACE IMPLEMENTATIONS ////

	// IShellLoaderIndicator

	public function start():void
	{
		for (var i:int=0; i<dots.length; i++) {
			moveDot(dots[i], true);
		}
		tickTimer.start();
	}

	public function stop():void
	{
		tickTimer.stop();
	}

	public function showPercent(newPercent:Number):void
	{
	
	}

}

}
