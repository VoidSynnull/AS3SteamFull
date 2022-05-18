package game.scenes.survival1.shared.components
{
	import flash.display.DisplayObject;
	
	import ash.core.Component;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.motion.ShakeMotion;
	
	public class ThermostatGaugeComponent extends Component
	{
		public var active:Boolean = false;
		public var alertTemp:Number = 22;
		public var coldCounter:Number = 0;
		public var freezingWater:Boolean = false;
		public var heatCounter:Number = 0;
		public var hidden:Boolean = true;
		public var temperature:Number = 98.6;
		public var shakeDepth:Number = 1;
		public var coldTimer:uint = 20;
		public var heatTimer:uint = 8;
		public var step:uint = 1;
		public var tweening:Boolean = false;
		
		public var alarmOff:Boolean = true;
		
		public var shakeMotion:ShakeMotion;
		public var moved:Boolean = false;
		public var frozen:Boolean = false;
		
		public var maskSpatial:Spatial;
		public var thermostat:Display;
		public var thermostatTween:Tween;
		public var blueOrbDisplayObject:DisplayObject;
		public var blueLiquidDisplayObject:DisplayObject;
		public var redOrbDisplayObject:DisplayObject;
		public var redLiquidDisplayObject:DisplayObject;
	}
}