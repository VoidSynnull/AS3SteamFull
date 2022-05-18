package game.scenes.myth.shared.components
{
	import ash.core.Component;
	
	public class CloudMass extends Component
	{		
		public var maxClouds:Number = 20;
		public var startClouds:Number = 10;
		
		public var clouds:Vector.<Cloud>;
		
		public var dead:Boolean = false;
		public var hit:Boolean = false;
		public var cooldown:Number = 0;
		public var resetTimer:Number = 15;
		public var invincible:Boolean = false;
		
		public function CloudMass()
		{
			clouds = new Vector.<Cloud>();
		}
		
		public function killCloud( num:int = 1 ):void
		{
			var cloud:Cloud;
			for (var i:int = 0; i < num; i++) 
			{
				cloud = clouds.pop();
				if( cloud )
				{
					cloud.attached = false;
					cloud.state = cloud.KILL;
					hit = true;
				}
			}
		}
	}
}