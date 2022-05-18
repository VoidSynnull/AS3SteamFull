package game.components.scene
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class SceneInteraction extends Component
	{
		public var activated:Boolean = false;	
		
		public var approach:Boolean = true;			// if true, will cause interacting Entity to move to current Entity's position
		//public var follow:Boolean = false;
		public var interactorID:String = "player";  // TODO : rework this so we aren't hardcoding the player.
		public var offsetX:Number = 0;
		public var offsetY:Number = 0;
		public var targetX:Number = 0;
		public var targetY:Number = 0;
		public var lockInput:Boolean = false;       				// should player input be locked when this is triggered?
		public var reached:Signal = new Signal(Entity, Entity);     // dispatches a signal with the interactor, interactedWith entitys as arguments when interaction position is reached
		public var triggered:Signal = new Signal(Entity, Entity);   // dispatches a signal with the interactor, interactedWith entitys as arguments when interaction is triggered
		public var offsetDirection:Boolean = false  				// if true upon reached character will face spatial + offset, if false character will face only spatial.
		public var faceDirection:String = "";
		public var ignorePlatformTarget:Boolean = true;
		public var minTargetDelta:Point = new Point( 100, 100 );
		public var validCharStates:Vector.<String>;					// list of valid char states
		public var motionToZero:Vector.<String>;
		
		public var autoSwitchOffsets:Boolean = true;
		public var disabled:Boolean = false;
		
		override public function destroy():void
		{
			reached.removeAll();
			triggered.removeAll();
			
			super.destroy();
		}
	}
}
