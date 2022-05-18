package game.components.multiplayer.chat
{
	import ash.core.Component;
	
	public class MenuBalloonRow extends Component
	{
		public function MenuBalloonRow($string:String, $id:int, $state:int){
			string = $string;
			id = $id;
			state = $state;
		}
		
		public var string:String;
		public var id:int;
		public var state:int;
		public var reply:Boolean;
		public var buttonHandler:String;
		public var buttonParam:String;
	}
}
