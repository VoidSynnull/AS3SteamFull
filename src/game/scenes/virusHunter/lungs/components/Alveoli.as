package game.scenes.virusHunter.lungs.components 
{
	import ash.core.Component;
	
	public class Alveoli extends Component
	{
		public var isHit:Boolean;
		public var isMoving:Boolean;
		public var elapsedTime:Number;
		public var waitTime:Number;
		
		public function Alveoli()
		{
			this.isHit = false;
			this.isMoving = false;
			this.elapsedTime = 0;
			this.waitTime = 0;
		}
	}
}