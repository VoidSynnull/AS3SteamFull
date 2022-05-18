package game.components.entity.character.animation
{	
	import ash.core.Component;
	
	public class AnimationSlot extends Component
	{
		public var priority:int;				// slot's priority, 0 being lowest
		public var active:Boolean = false;		// whether slot is actively or not (inactive slots do not apply their animations)
		public var reload:Boolean = false;		// flag for slot to reload its data to parts ( reloaded by RigAnimationLoaderSystem )
	}
}
