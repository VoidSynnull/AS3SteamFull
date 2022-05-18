package game.scenes.carnival.apothecary.chemicals
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import nape.callbacks.CbType;
	import nape.phys.Body;

	public interface IChem
	{
		function get body():Body;
		function set bondPoint($point:Point):void;
		function get bondPoint():Point;
		function set compound($compound:Compound):void;
		function get compound():Compound;
		function get bodyDisplay():DisplayObject;
		function set reactsWith($class:Class):void;
		function get reactsWith():Class;
		function checkForCollisions():void;
		function removeCollisions():void;
		function get thisClass():Class;
		function changeCBType($cbType:CbType):void;
		function get allowedReactions():int;
		function get reactions():Vector.<Object>;
		function set position($string:String):void;
		function get position():String;
		function set reactive($boolean:Boolean):void;
		function get reactive():Boolean;
		function set leftBondOffset($point:Point):void;
		function get leftBondOffset():Point;
		function set rightBondOffset($point:Point):void;
		function get rightBondOffset():Point;
		function bondOffset($point:Point):void;
		function resetBondOffset():void;
		function set leftBondRotation($rotation:Number):void;
		function get leftBondRotation():Number;
		function set rightBondRotation($rotation:Number):void;
		function get rightBondRotation():Number;
		function bondRotation($rotation:Number):void;
		function resetBondRotation():void;
	}
}