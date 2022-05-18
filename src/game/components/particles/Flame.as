package game.components.particles
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Component;
	
	import game.data.particles.FlameData;
	import game.util.BitmapUtils;
	
	public class Flame extends Component
	{
		public var clip:MovieClip;
		
		/**
		 * This BitmapData is created right when the Component is constructed and is shared between all
		 * flames created in FlameSystem for this Entity.
		 */
		public var data:BitmapData;
		
		public var container:DisplayObjectContainer;
		public var isFront:Boolean;
		
		public var flames:Vector.<FlameData> = new Vector.<FlameData>();
		public var pool:Vector.<FlameData> = new Vector.<FlameData>();
		
		public var time:Number;
		public var wait:Number;
		
		public function Flame(clip:MovieClip, isFront:Boolean, wait:Number = 0.2)
		{
			this.data 		= BitmapUtils.createBitmapData(clip);
			this.clip		= clip;
			this.container 	= clip.parent;
			this.container.removeChild(clip);
			
			this.isFront = isFront;
			
			this.time = 0;
			this.wait = wait;
		}
		
		override public function destroy():void
		{
			this.flames 	= null;
			this.pool 		= null;
			this.clip		= null;
			this.container 	= null;
			
			this.data.dispose();
			this.data = null;
			
			super.destroy();
		}
	}
}