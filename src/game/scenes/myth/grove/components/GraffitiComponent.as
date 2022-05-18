package game.scenes.myth.grove.components
{
	import ash.core.Component;
	
	public class GraffitiComponent extends Component
	{
		public function GraffitiComponent( _number:int )
		{
			number = _number;
		}
		
		public var active:Boolean = true;
		public var number:int;
	}
}