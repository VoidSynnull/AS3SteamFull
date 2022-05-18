package game.scenes.myth.labyrinth.components
{
	import ash.core.Component;
	
	public class BoneComponent extends Component
	{
		public function BoneComponent( keeper:Boolean = false, on:Boolean = true )
		{
			this.keeper = keeper;
			this.on = on;
		}
		
		public var keeper:Boolean;
		public var on:Boolean;
		public var transition:Boolean = false;
	}
}