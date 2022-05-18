package game.components.motion
{
	import ash.core.Component;
	
	public class Magnetic extends Component
	{
		public function Magnetic(polarity:uint = 0)
		{
			this.polarity = polarity;
		}
		
		public var polarity:uint;
	}
}