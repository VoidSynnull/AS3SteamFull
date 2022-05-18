package game.scenes.backlot.cityDestroy.components
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class BalloonComponent extends Component
	{
		public var number:int;
		
		public var hit:MovieClip;
		public var ropeEmpty:MovieClip;
		
		public var rope:Entity;
		public var balloon:Entity;
		
		public var holdingRope:Sprite;
		
		public var state:String = 		"idle";
		public var popped:Boolean = false;
		
		public var pop:Signal;
		
		public function BalloonComponent()
		{
			pop = new Signal(int);
		}
	}
}