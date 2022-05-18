package game.scenes.cavern1.shared.components
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class MagneticData extends Component
	{
		private var _polarity:int = 1;
		private var _radius:Number = 0;
		
		public var polarityChanged:Signal = new Signal();
		public var radiusChanged:Signal = new Signal();
		
		public function MagneticData(polarity:int = 1, radius:Number = 200)
		{
			this.polarity = polarity;
			this.radius = radius;
		}
		
		public function get polarity():int { return _polarity; }
		public function set polarity(value:int):void
		{
			if(_polarity != value)
			{
				var previous:Number = _polarity;
				_polarity = value;
				polarityChanged.dispatch(this, previous);
			}
		}
		
		/**
		 * The radius of the magnetic where things can start being affected.
		 */
		public function get radius():Number { return _radius; }
		public function set radius(value:Number):void
		{
			if(_radius != value)
			{
				var previous:Number = _radius;
				_radius = value;
				radiusChanged.dispatch(this, previous);
			}
		}
	}
}