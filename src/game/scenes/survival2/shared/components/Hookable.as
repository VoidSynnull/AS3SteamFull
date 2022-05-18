package game.scenes.survival2.shared.components
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Hookable extends Component
	{
		public const IDLE_STATE:int 	= 0;
		public const REELING_STATE:int 	= 1;
		public const REELED_STATE:int 	= 2;
		
		public var state:int = IDLE_STATE;
		
		public var _hitHook:Boolean = false;	// If in contatc with hook. Should only be changed by the HookSystem.
		
		//The Hook Entity hooking the Hookable Entity.
		//public var hook:Entity;
		
		//A Dictionary of Hook Entities colliding with the Hookable Entity.
		//public var hooks:Dictionary = new Dictionary();
		
		/*
		These are offsets for where the Hookable Entity should be when it is hooked.
		*/
		public var offsetX:Number = 0;
		public var offsetY:Number = 0;
		
		public var bait:String = "any";
		
		/**
		 * If true, once the Entity is fully reeled in, it'll be removed from the scene.
		 */
		public var remove:Boolean = false;
		
		/**
		 * The Entity that has hooked this Hookable Entity. Should only be changed by the HookSystem.
		 */
		//public var hookEntity:Entity;
		
		/**
		 * Signal dispatched when a Hookable Entity is given the wrong bait, being reeled in, has been reeled in,
		 * and has been dropped by a Hook Entity when it was removed from the HookSystem.
		 */
		public var wrongBait:Signal = new Signal(Entity, Entity);
		public var reeling:Signal 	= new Signal(Entity, Entity);
		public var reeled:Signal 	= new Signal(Entity, Entity);
		public var dropped:Signal	= new Signal(Entity, Entity);
		
		public function Hookable()
		{
			
		}
	}
}