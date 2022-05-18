package game.scenes.poptropolis.skiing
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class GatePartner extends Component
	{
		private var _partner:Entity
		
		public function GatePartner(e:Entity = null)
		{
			_partner = e
		}
		
		public function get partner():Entity
		{
			return _partner;
		}
		
		public function set partner(value:Entity):void
		{
			_partner = value;
		}
		
	}
}

