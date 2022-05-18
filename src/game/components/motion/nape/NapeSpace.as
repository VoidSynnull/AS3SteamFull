package game.components.motion.nape
{
	import ash.core.Component;
	
	import nape.space.Space;
	import nape.util.Debug;
	
	public class NapeSpace extends Component
	{		
		public function NapeSpace(space:Space, debug:Debug = null)
		{
			this.space = space;
			this.debug = debug;
		}
		
		public var space:Space;
		public var debug:Debug;
	}
}