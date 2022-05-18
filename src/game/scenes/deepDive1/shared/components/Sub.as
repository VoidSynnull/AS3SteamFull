package game.scenes.deepDive1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.scenes.deepDive1.shared.emitters.SubTrail;
	
	public class Sub extends Component
	{
		public function Sub()
		{
		}
		
		public var engineSoundFadeOut:Boolean = false;
		public var trail:SubTrail;
		public var camera:Entity;
	}
}