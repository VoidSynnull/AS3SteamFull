/**
 * General hit zones that dispatch when collided with.
 */

package game.components.hit
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Zone extends Component
	{
		public function Zone()
		{
			
		}
		
		override public function destroy():void
		{
			inside.removeAll();
			entered.removeAll();
			exitted.removeAll();
			
			super.destroy();
		}
		
		public var inside:Signal = new Signal(String, String);
		public var entered:Signal = new Signal(String, String);
		public var exitted:Signal = new Signal(String, String);
		public var pointHit:Boolean = false;
		private var _shapeHit:Boolean = false;
		
		public function get shapeHit():Boolean 	{ return _shapeHit; }
		public function set shapeHit( bool:Boolean ):void 
		{
			pointHit = !bool;
			_shapeHit = bool;
		}
	}
}