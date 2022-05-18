package game.scenes.reality2.spearThrow.ai
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import game.data.WaveMotionData;
	
	import org.osflash.signals.Signal;
	
	public class AiInput extends Component
	{
		public var aimRadius:Number;//radius of the target
		public var accuracy:Number;//inteligence of ai(0-1)
		public var delay:Number;//how fast ai progresses
		public var time:Number;//tracks delay time
		public var movements:int;//how many aim adjustments made
		public var count:int;//tracks movements
		public var target:Point;//arrow aiming point
		public var aiming:Boolean;//handling aiming
		public var fire:Signal;//makes final aim decision
		public var powerBar:WaveMotionData;
		
		public function AiInput(powerBar:WaveMotionData, accuracy:Number =1, aimRaduis:Number = 100, delay:Number = .5, movements:int = 3)
		{
			this.powerBar = powerBar;
			this.aimRadius = aimRaduis;
			this.accuracy = accuracy;
			this.delay = delay;
			this.movements = movements;
			count = 0;
			time = 0;
			target = new Point();
			aiming = false;
			fire = new Signal();
		}
	}
}