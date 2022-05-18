package game.scenes.examples.bounceMaster.components
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class BounceMasterGameState extends Component
	{
		public var gameActive:Boolean = false;
		public var gameStarted:Boolean = false;
		public var gameOver:Signal = new Signal();
		public var addNewBouncerWait:Number = 0;
		public var addNewBouncer:Boolean = true;
		public var totalHits:int = 0;
		public var hitTimeWait:Number = 0;
		public var lives:Number;
		public var multiplierTime:Number = 0;
	}
}