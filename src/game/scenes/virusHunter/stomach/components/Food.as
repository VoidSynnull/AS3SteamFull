package game.scenes.virusHunter.stomach.components 
{
	import ash.core.Component;
	
	import game.components.Emitter;
	
	public class Food extends Component
	{
		public var state:String;					//Current state of the food
		public var emitter:Emitter;					//Particles for stomach acid splashes
		public var alphaRate:Number;				//Alpha rate to digest food
		public var scaleRate:Number;				//Scale rate to digest food
		
		//Food states determined by FoodSystem
		public static const IDLE_STATE:String 		= "idle_state";
		public static const SPAWNING_STATE:String	= "spawning_state";
		public static const FALLING_STATE:String 	= "falling_state";
		public static const SURFACING_STATE:String	= "surfacing_state";
		public static const FLOATING_STATE:String	= "floating_state";
		public static const DIGESTING_STATE:String	= "digesting_state";
		
		public function Food(emitter:Emitter)
		{
			this.state = Food.IDLE_STATE;
			this.emitter = emitter;
			this.alphaRate = 0;
			this.scaleRate = 0;
		}
	}
}