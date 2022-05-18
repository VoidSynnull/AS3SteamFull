package game.scenes.deepDive2.medusaArea.components 
{
	import ash.core.Component;
	
	public class MedusaSwitch extends Component
	{
		public var open:Boolean = false;
		public var idNum:uint;
		
		public function MedusaSwitch(id)
		{
			idNum = id;
		}
	}
}