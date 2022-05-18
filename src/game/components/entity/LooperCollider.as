package game.components.entity
{
	import ash.core.Component;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	
	public class LooperCollider extends Component
	{
		public function LooperCollider(trigger:Function = null):void
		{
			// remember trigger function
			triggerFunction = trigger;
		}
		
		public var isHit:Boolean = false;
		public var collisionType:String;	 
//		public var ignoreNextHit:Boolean = false;            // Will cause an entity to 'ignore' the next platform hit and pass through it.
//		public var baseGround:Boolean;				 // True when en entity is on the 'floor' boundary of a scene.
//		public var adjustMotion:Boolean = false;
		
		public var hitDisplay:Display;
		public var hitEdge:Edge;
		public var hitMotion:Motion;
		public var hitSpatial:Spatial;
		public var triggerFunction:Function;
	}
}