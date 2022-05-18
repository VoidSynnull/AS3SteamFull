package game.scenes.poptropolis.skiing.components
{
	import ash.core.Component;
	
	public class ObstacleType extends Component
	{
		private var _type:String
		
		public function ObstacleType(str:String)
		{
			_type = str
		}
		
		public function get type():String
		{
			return _type;
		}
		
		public function set type(value:String):void
		{
			_type = value;
		}
		
	}
}

