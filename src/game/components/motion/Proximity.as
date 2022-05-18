package game.components.motion {

import ash.core.Component;

/**
 * The <code>Proximity</code> component specifies a two-dimensional hotspot region,
 * whose boundary is configurable by several means, within a <code>Scene</code>.
 * It dispatches a <code>Signal</code> containing a reference
 * to its owning <code>Entity</code> when  a <code>ProximitySystem</code>
 * detects an entry or exit by its owning <code>Entity</code>.
 * Any <code>Entity</code> containing both a
 * <code>Spatial</code> and a <code>Proximity</code> component becomes a
 * <code>ProximityNode</code> and is processed by the <code>ProximitySystem</code>.
 * 
 * <p>The idea here is to add a <code>Proximity</code> component to any <code>Entity</code>
 * which can move around. The limitation is that since an <code>Entity</code> can contain
 * only one of given class of <code>Component</code>, there can be only one such region per
 * <code>Entity</code>. Until we create a ProximityList component, I guess.</p>
 * 
 * @author Bard McKinley/Rich Martin
 * 
 */
public class Proximity extends Component {
	import ash.core.Entity;
	import engine.components.Spatial;
	import org.flintparticles.twoD.zones.Zone2D;
	import org.osflash.signals.Signal;
	
	public var entered:Signal;
	public var exited:Signal;
	public var id:String;
	public var threshold:int;		// how close, in pixels
	public var hotSpot:Spatial;		// the center point of the circle or square
	public var isInside:Boolean = false;
	/**
	 * If not a circle or square, specify an implementor of the flintparticles.twoD.zones.Zone2D interface.
	 * There are a lot of exotic zones you can specify.
	 * @see org.flintparticles.twoD.zones.Zone2D
	 */	
	public var zone2D:Zone2D = null; 

	// all three of these flags are set by default, but ProximitySystem will
	// process them in lazy order. I.e., zone proximity tests will only be evaluated
	// if circularTest and squareTest are cleared.
	private var _square:Boolean = true;
	private var _circle:Boolean = true; 
	private var _zone:Boolean = true;

	public function Proximity( threshold:int, targetSpatial:Spatial) {
		this.threshold = threshold;
		if ( targetSpatial ) {
			this.hotSpot = targetSpatial;
		} else {
			trace("WARNING: If no hotspot is provided, this Proximity will be ineffective until its circle and square flags are cleared and a Zone2D is specified.");
		}
		
		entered = new Signal(Entity);
		exited  = new Signal(Entity);
	}

	/**
	 * Indicates whether or not to perform a square proximity test.
	 * The highest priority test, and the simplest.
	 */	
	public function get squareTest():Boolean	{ return _square; }
	/**
	 * @private
	 */	
	public function set squareTest( bool:Boolean ):void {
		_square = false;
		if ( bool ) {
			_circle = _zone = false; 
			_square = true; 
		}
	}

	/**
	 * Indicates whether or not to perform a circle proximity test.
	 * The second highest priority test, which is more precise than a squareTest.
	 */	
	public function get circularTest():Boolean	{ return _circle; }
	/**
	 * @private
	 */	
	public function set circularTest( bool:Boolean ):void {
		_circle = false;
		if ( bool ) {
			_square = _zone = false; 
			_circle = true;
		}
		
	}

	/**
	 * Indicates whether or not to perform a Zone2D proximity test.
	 * The lowest priority test, but the most configurable.
	 */	
	public function get zoneTest():Boolean	{ return _zone; }
	/**
	 * @private
	 */	
	public function set zoneTest( bool:Boolean ):void {
		_zone = false;
		if ( bool ) {
			_circle = _square = false; 
			_zone = true; 
		}
	}

}

}
