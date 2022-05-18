package game.components.entity.character.animation
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;

	public class AnimationControl extends Component
	{
		public function AnimationControl()
		{
			_animSlots = new Vector.<Entity>;
		}

		public function get numSlots():int				{ return _animSlots.length; }
		public var primary:RigAnimation;				// Rig Animation at animation slot 0 ( here for convenience )
		private var _animSlots:Vector.<Entity>;			// All animation slot entities for single char ( see AnimationSlotCreator )
		
		// NOTE :: Want to institute something like this, will need a throough run animation run through first
		//public var noEmitters:Boolean = false;			// Flag that prevents emitters from being created in Aniamtion (up to individual animations ot uphold)
		
		/**
		 * Pause or unpause all animation slots
		 * @param	bool
		 */
		public function pause( bool:Boolean = true ):void
		{
			for each( var animSlot:Entity in _animSlots )
			{
				Timeline( animSlot.get(Timeline) ).paused = bool;
			}
		}
		
		/**
		 * Pause or unpause all animation slots
		 * @param	bool
		 */
		public function playing( bool:Boolean = true ):void
		{
			for each( var animSlot:Entity in _animSlots )
			{
				Timeline( animSlot.get(Timeline) ).playing = bool;
			}
		}
		
		/**
		 * Stop all Timelines of animation slots
		 * @param	bool
		 */
		public function stop():void
		{
			for each( var animSlot:Entity in _animSlots )
			{
				Timeline( animSlot.get(Timeline) ).stop();
			}
		}
		
		/**
		 * Stop all Timelines of animation slots
		 * @param	bool
		 */
		public function lock( bool:Boolean = true ):void
		{
			for each( var animSlot:Entity in _animSlots )
			{
				Timeline( animSlot.get(Timeline) ).lock = bool;
			}
		}
		
		/**
		 * Pause or unpause all animation slots
		 * @param	bool
		 */
		public function sleeping( bool:Boolean = true ):void
		{
			var sleep:Sleep;
			
			for each( var animSlot:Entity in _animSlots )
			{
				sleep = animSlot.get(Sleep);
				
				if(sleep)
				{
					sleep.sleeping = bool;
					sleep.ignoreOffscreenSleep = bool;
				}
			}
		}
		
		/**
		 * Remove sleep
		 */
		public function removeSleep():void
		{
			for each( var animSlot:Entity in _animSlots )
			{
				animSlot.remove(Sleep);
			}
		}
		
		/**
		 * Add an animation slot entity ( see AnimationSlotCreator )
		 * @param	animSlot
		 */
		public function addAnimSlot( animSlot:Entity ):void
		{
			_animSlots.push( animSlot );
		}
		
		/**
		 * Get animation slot entity at provided slot priority
		 * @param	priority
		 * @return
		 */
		public function getEntityAt( priority:int = 0 ):Entity
		{
			if ( priority > -1 && priority < _animSlots.length )
			{
				return _animSlots[priority];	
			}
			else
			{
				trace( " Error :: AnimationControl :: getAnimSlotAt :: No entity at priority " + priority );
				return null;
			}
		}
		
		/**
		 * Get RigAnimation component from animation slot entity at provided slot priority
		 * @param	priority
		 * @return
		 */
		public function getAnimAt( priority:int = 0 ):RigAnimation
		{
			var animEntity:Entity =  getEntityAt( priority );
			if ( animEntity )
			{
				return animEntity.get( RigAnimation );
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * Get AnimationSlot component from animation slot entity at provided slot priority
		 * @param	priority
		 * @return
		 */
		public function getSlotAt( priority:int = 0):AnimationSlot
		{
			var animEntity:Entity =  getEntityAt( priority );
			if ( animEntity )
			{
				return animEntity.get( AnimationSlot );
			}
			else
			{
				return null;
			}
		}
	}
}