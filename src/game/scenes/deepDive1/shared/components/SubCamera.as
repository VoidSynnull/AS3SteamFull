package game.scenes.deepDive1.shared.components
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.util.ColorUtil;
	
	public class SubCamera extends Component
	{
		
		/**
		 * Creates a camera component to be attached to the sub
		 * @param hud - the entity of the camera's HUD
		 * @param dist - the distance from the sub that the camera can reach
		 * @param ang - the greatest angle the sub can see the fish in degrees
		 * 
		 */
		public function SubCamera(hud:Entity, maxAngle:Number, minDist:Number, maxDist:Number)
		{
			this.hud = hud;
			this.angle = maxAngle;
			this.distanceMin = minDist;
			this.distanceMax = maxDist;
		}
		
		public var hud:Entity;
		public var startFilm:Boolean;
		public var distanceMin:Number;
		public var distanceMax:Number;
		public var angle:Number;
		public var lights:Vector.<MovieClip>;
		public var topLight:Entity;
		public var iris:Entity;
		public var lightBeamR:Entity;
		public var lightBeamL:Entity;
		public var originalColor:uint;
		public var flashColor:String;
		public var numberOfFlashes:Number = 10;
		public var spotLightsOn:Boolean = false;
		
		public static const RED:String = "red";
		public static const GREEN:String = "green";
		public static const ORIGINAL:String = "gray";
		public static const COLOR_RED:Number = 0xFF0000;
		public static const COLOR_GREEN:Number = 0x00FF00;
		public static const COLOR_YELLOW:Number = 0xFFFF00;
		
		/**
		 * 
		 * @param index - index of light of recording light to change color
		 * @param color - color of recording lights
		 * @param reverse - determines from which direction lighst start to tick off
		 * 
		 */
		public function changeLight(index:int, color:uint, reverse:Boolean = false):void
		{
			if(reverse)
				index = lights.length - 1 - index;
				
			ColorUtil.colorize(lights[index], color);
		}
		
		public function changeAllLightColors(color:uint):void
		{
			for each(var mc:MovieClip in lights)
			{
				ColorUtil.colorize(mc, color);
			}
		}
		
		public function changeTopLight(color:String):void
		{
			topLight.get(Timeline).gotoAndStop(color);
		}
		
		public function changeBack():void
		{
			changeAllLightColors(originalColor);
			topLight.get(Timeline).gotoAndStop(ORIGINAL);
		}
		
		override public function destroy():void
		{
			super.destroy();
			lights = null;
		}
	}
}