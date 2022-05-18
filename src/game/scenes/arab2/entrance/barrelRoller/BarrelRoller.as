package game.scenes.arab2.entrance.barrelRoller
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	
	import ash.core.Component;
	
	public class BarrelRoller extends Component
	{
		public var time:Number = 0;
		public var wait:Number = 0;
		public var minWait:Number = 3;
		public var maxWait:Number = 5;
		
		public var rollVelocity:Number = 200;
		public var makeHazard:Boolean = true;
		
		public var barrelDisplay:DisplayObject;
		public var barrelBitmapData:BitmapData;
		
		internal var _automaticRoll:Boolean = true;
		internal var _manualRoll:Boolean = false;
		
		public function BarrelRoller()
		{
			super();
		}
		
		public function get automaticRoll():Boolean
		{
			return this._automaticRoll;
		}
		
		public function set automaticRoll(automaticRoll:Boolean):void
		{
			this._automaticRoll = automaticRoll;
			this.time = 0;
		}
		
		public function manualRoll():void
		{
			this._manualRoll = true;
		}
	}
}