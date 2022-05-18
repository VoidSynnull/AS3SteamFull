package game.components.specialAbility.character
{	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class Toss extends Component
	{
		public var item:Entity;
		public var player:Entity;
		public var vy:int = -40;
		public var ay:int =   2;
		
		
		public function Toss(_item:Entity, _player:Entity)
		{
			item = _item;
			player = _player;
		}
	}
}