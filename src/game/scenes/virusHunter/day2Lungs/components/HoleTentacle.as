package game.scenes.virusHunter.day2Lungs.components 
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.day2Lungs.data.HoleData;
	
	public class HoleTentacle extends Component
	{
		public var data:HoleData;
		public var isTransitioning:Boolean;
		
		public function HoleTentacle(data:HoleData)
		{
			this.data = data;
			this.isTransitioning = false;
		}
	}
}