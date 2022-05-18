package game.scenes.deepDive1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Provide to Entities that can be filmed by the SubCamera
	 * @author Scott W
	 */
	public class Filmable extends Component
	{
		// Just so the system picks any fish that the camera should want
		public function Filmable(duration:Number, isFilmable:Boolean = false)
		{
			cameraTime = duration;
			this.isFilmable = isFilmable;
		}	
		
		private var _attemptFilm:Boolean = false;
		public function get attemptFilm():Boolean { return _attemptFilm; } 
		public function set attemptFilm( bool:Boolean):void
		{ 
			_attemptFilm = bool; 
		} 
		
		public var activated:Boolean = false;
		public var isFilmable:Boolean = true;
		public var cameraTime:Number;	// duration necessary to film, in seconds
		public var stateSignal:Signal = new Signal(Entity);
		public var state:String = "";
		public var captured:Boolean = false;
		public var hasIntro:Boolean = false;
	
		public function onPress( ...args ):void	
		{ 
			this.attemptFilm = true; 
		}
		
		public const FILMING_OUT_OF_RANGE:String = "film_range";
		public const FILMING_BLOCK:String = "film_block";
		public const FILMING_START:String = "film_start";
		public const FILMING_STOP:String = "film_stop";
		public const FILMING_COMPLETE:String = "film_complete";
	}
}