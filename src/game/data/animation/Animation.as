package game.data.animation 
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.data.animation.entity.RigAnimationData;
	
	/**
	 * ...
	 * @author billy
	 * 
	 * A base class for all rig animation classes.
	 */
	public class Animation
	{
		public var components:Array;
		public var systems:Array;
		public var data:RigAnimationData;
		public var dataLoaded:Boolean = false;
		
		public static const LABEL_BEGINNING : String 	= "beginning";
		public static const LABEL_ENDING : String 		= "ending";
		public static const LABEL_LOOP : String 		= "loop";
		public static const LABEL_TRIGGER : String 		= "trigger";
		
		/**
		 * Add components if they aren't already added.
		 */
		public function addComponentsTo(entity:Entity):void
		{
			
		}
		
		/**
		 * Initialize the Animation class with RigAnimationData
		 * @param	data : Contains all frames of animation mapping joints to the current position defined in the animation.
		 */
		public function init(data:RigAnimationData):void
		{
			this.data = data;
			dataLoaded = true;
		}
		
		/**
		 * Called by RigAnimationLoaderSystem when a new animation loads that no longer requires the previous animations components.
		 * @param	entity
		 */
		public function remove(entity:Entity):void
		{
			if (components != null)
			{
				// remove components if they are no longer needed.
				var component:Component;
				var componentClass:Class;

				for (var n:Number = 0; n < components.length; n++)
				{
					componentClass = components[n];
					component = entity.get(componentClass);
					
					if (component != null)
					{
						if (component.nodesAddedTo <= 1)
						{
							entity.remove(componentClass);
						}
					}
				}
			}
		}
		
		/**
		 * Called by TimelineLabelSystem when a label is detected within Timeline
		 * @param	entity
		 * @param	label
		 */
		public function reachedFrameLabel( entity:Entity, label:String ):void
		{
		}
	}

}