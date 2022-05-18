package game.scenes.poptropolis.weightLift.components 
{
	import ash.core.Component;
	
	public class Target extends Component
	{
		public var wait:Number = 0;
		public var lifting:Boolean = false;
		public var counter:Number = 60 * 99;
		public var speedVariable:Number = 90;
		public var speedVariable2:Number = 100;
		public var speed:Number = 0.012;
		public var speedEase:Number = 0;
		public var countSound:Number = 11;
		
		//bonus
		public var showBonus:Boolean = false;
		public var currWeight:Number = 100;
		public var finalScore:Number = 0;
		
		//waitfordrop
		public var waitForDrop:Number = 0;
		
		public function Target()
		{
			//this.mouse = mouse;
		}
	}
}