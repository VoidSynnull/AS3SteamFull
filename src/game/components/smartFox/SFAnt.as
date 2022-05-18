package game.components.smartFox
{
	import ash.core.Component;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	public class SFAnt extends Component
	{
		public var last_sent_spatial:Spatial;
		public var last_sent_motion:Motion;
	}
}