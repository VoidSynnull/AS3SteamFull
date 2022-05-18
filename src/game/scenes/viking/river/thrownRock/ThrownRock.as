package game.scenes.viking.river.thrownRock
{
	import flash.display.DisplayObject;
	
	import ash.core.Component;
	
	public class ThrownRock extends Component
	{
		private var _active:Boolean = false;
		public var maxHeight:Number = 200;
		public var throwTime:Number = 3;
		public var elapsedTime:Number = 0;
		
		public var shadow:DisplayObject;
		
		public function ThrownRock()
		{
			
		}
		
		public function get active():Boolean
		{
			return this._active;
		}
		
		public function set active(active:Boolean):void
		{
			this._active = active;
			this.shadow.visible = active;
		}
	}
}