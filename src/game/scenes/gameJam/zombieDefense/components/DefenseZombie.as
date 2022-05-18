package game.scenes.gameJam.zombieDefense.components
{	
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class DefenseZombie extends Component
	{
		public var active:Boolean = false;
		
		public var health:int;
		public var statusEffect:String = "none";
		public var effectDuration:Number = 0;
		public var effectTimer:Number = 0;

		public var path:Array;
		public var pathIndex:int = 0;
		
		public var stateChanged:Signal;
		
		public function DefenseZombie(health:int = 0)
		{
			this.path = new Array();
			this.health = health;
			stateChanged = new Signal();
		}
		
		override public function destroy():void
		{
			stateChanged.removeAll();
			stateChanged = null;
		}
		
		public function getNextPathPt():Point
		{
			pathIndex++;
			var pt:Point;
			if(pathIndex < path.length){
				pt = path[pathIndex];
				return pt;
			}
			return null;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}