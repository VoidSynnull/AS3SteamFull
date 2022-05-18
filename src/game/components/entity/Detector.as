package game.components.entity
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	/**
	 * 
	 * @author Scott Wszalek
	 * 
	 */	
	public class Detector extends Component
	{
		/**
		 * 
		 * @param ang - angle of cone in degrees
		 * @param dist - size of cone, distance to check
		 * @param offset - offset camera starting angle
		 * 
		 */		
		public function Detector(ang:Number, dist:Number, offset:Number = 90)
		{
			angle = ang;
			distance = dist;
			this.offset = offset;
			detectorHit = new Signal(Entity);
		}
		
		public var angle:Number;
		public var distance:Number;
		public var offset:Number;
		
		public var detectorHit:Signal;
	}
}