package game.creators.entity
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.character.Rig;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMaster;
	import game.util.EntityUtils;

	/**
	 * Creates entities that fucntion as animation slots for rig animated character.
	 */
	public class AnimationSlotCreator
	{	
		/**
		 * Creates an 'aniamtion slot' entity for the specified rig animated character.
		 * @param	groupManager
		 * @param	character - entity animation slot will animate.
		 * @param	rigAnim	- RigAniamtion that will exist within slot.
		 * @param	priority - priority in which the slot's animation will apply.  Higher priorities will overirde lower priorities, 0 being the lowest.
		 * @param	group
		 * @param	systemManager
		 * @return
		 */
		public static function create( character:Entity, rigAnim:RigAnimation = null, priority:int = -1, group:Group = null ):Entity
		{
			var animControl:AnimationControl = character.get(AnimationControl)
			
			// TODO :: add checks for Rig & AnimationControl
			if ( priority > -1 && priority < animControl.numSlots )
			{
				trace( "AnimationSlotCreator :: create :: Animation slot already exists at " + priority );
				return null;
			}
			else
			{
				var animSlotEntity:Entity = new Entity();
				priority = animControl.numSlots;
				
				// add AnimationControl from character
				animSlotEntity.add( animControl );
				
				// add Rig from character
				animSlotEntity.add( character.get(Rig) );
				
				// add character as Parent
				EntityUtils.addParentChild(animSlotEntity, character);
				
				// add new Timeline
				var timeline:Timeline = new Timeline();
				animSlotEntity.add( timeline );
				
				// add new RigAnimation
				if ( !rigAnim )
				{
					rigAnim = new RigAnimation();
				}
				animSlotEntity.add( rigAnim );
				
				// add new TimelineMaster (flag to prevent entities that share Timeline from updating it)
				animSlotEntity.add( new TimelineMaster() );
				
				// add new AnimationSequencer
				var animSequencer : AnimationSequencer = new AnimationSequencer();
				animSequencer.start = true;	// triggers AnimationSequencer to begin a new animation
				animSlotEntity.add( animSequencer );
				
				// add new AnimationSlot
				var animSlot : AnimationSlot = new AnimationSlot();
				animSlot.priority = priority;
				animSlotEntity.add( animSlot );	

				if ( priority == 0 )
				{
					animControl.primary = rigAnim;
					character.add( rigAnim );
					character.add( timeline );
				}
				
				animControl.addAnimSlot( animSlotEntity );
				
				if ( group == null )
				{
					group = EntityUtils.getOwningGroup( character );
				}
				
				group.addEntity( animSlotEntity );
				
				return animSlotEntity;
			}
		}
	}
}
