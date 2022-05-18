package game.scenes.backlot.cityDestroy.components
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class SearchLightComponent extends Component
	{
		public var beam:Entity;
		public var base:Entity;
		public var explosion:Entity;
		
		public var hit:MovieClip;
		
		public var state:String = "idle";
	}
}