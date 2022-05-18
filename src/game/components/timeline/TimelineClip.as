package game.components.timeline
{	
	import flash.display.MovieClip;
	import ash.core.Component;
	
	public class TimelineClip extends Component
	{
		public function TimelineClip( mc:MovieClip = null )
		{
			if ( mc )
			{
				this.mc = mc;
			}
		}
		public var mc:MovieClip;	 
	}
}
