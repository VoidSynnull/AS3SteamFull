package game.scenes.poptropolis.archery.components 
{	
	import ash.core.Component;
	
	public class Wind extends Component
	{
		public var windSpeed:Number;
		
		public function Wind()
		{
			windSpeed = Math.random()*100 - 50;
		}
	}
}