package game.scenes.virusHunter.shared.components
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	public class KillCount extends Component
	{
		public function KillCount()
		{
			this.count = new Dictionary();
		}
		
		public var count:Dictionary;
	}
}