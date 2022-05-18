package game.components
{
	import ash.core.Component;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class Emitter extends Component
	{
		public var emitter:Emitter2D;
		public var remove:Boolean = false;          // should this emitter entity be removed when it completes emitting particles (ex : water splash)
		public var removeOnSleep:Boolean = false;   // should this emitter be removed when it goes to sleep (ex if a particle effect occurs offscreen, you probably don't want it to be created)
		
		public var start:Boolean = false;
		public var pause:Boolean = false;
		public var resume:Boolean = false;
		public var stop:Boolean = false;
	}
}
