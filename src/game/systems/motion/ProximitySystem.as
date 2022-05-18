package game.systems.motion {
	
import ash.core.Engine;
import ash.tools.ListIteratingSystem;

/**
 * Examines a <code>NodeList</code> of <code>ProximityNodes</code> and
 * causes each <code>Proximity</code> component to dispatch a
 * <code>Signal</code> whenever its owning <code>Entity</code> enters or exits its
 * two-dimensional hot zone.
 * @author Bard McKinley/Rich Martin
 * 
 */
public class ProximitySystem extends ListIteratingSystem {

	import flash.geom.Point;
	import flash.geom.Rectangle;
	import engine.components.Spatial;
	import game.components.motion.Proximity;
	import game.nodes.motion.ProximityNode;
	import game.systems.SystemPriorities;
	import org.flintparticles.twoD.zones.Zone2D;

	public function ProximitySystem() {
		super( ProximityNode, updateNode);
		super._defaultPriority = SystemPriorities.update;	// TODO :: may want to change priority?
	}

	public override function addToEngine( systemManager : Engine ) : void {
		super.addToEngine(systemManager);
		this.systemManager = systemManager;
	}


	 private function updateNode(node:ProximityNode, elapsedTime:Number):void
	{
		var proximity:Proximity = node.proximity;
		var center:Spatial = node.proximity.hotSpot;

		var closeEnough:Boolean = false;
		var spatial:Spatial = node.currentLoc;

		if ( proximity.squareTest ) {
			closeEnough = withinSquare(spatial, center, proximity.threshold);

		} else if ( proximity.circularTest ) {
			closeEnough = withinCircle(spatial, center, proximity.threshold);

		} else if ( proximity.zoneTest ) {
			if ( proximity.zone2D ) {
				closeEnough = withinZone(spatial, proximity.zone2D);
			}

		} else {
			trace( "Error :: ProximitySystem :: updateNode :: No circle, rectangle or zone2D has been specified. Skipping over useless node." );
			return;		// don't send any signals when there's an error
		}

		if (closeEnough) {
			inside(node);
		} else {
			outside(node);
		}
	}

	private function withinSquare(spatial:Spatial, hotSpot:Spatial, threshold:int):Boolean {
		var hotRect:Rectangle = new Rectangle(hotSpot.x - threshold/2, hotSpot.y - threshold/2, threshold, threshold);
		return hotRect.contains(spatial.x, spatial.y);
	}

	private function withinCircle(spatial:Spatial, hotSpot:Spatial, threshold:int):Boolean {
		var dist:int = Point.distance(new Point(spatial.x, spatial.y), new Point(hotSpot.x, hotSpot.y));
		return dist <= threshold;
	}

	private function withinZone(spatial:Spatial, zone:Zone2D):Boolean {
		return zone.contains(spatial.x, spatial.y);
	}

	private function inside( node:ProximityNode):void {
		if ( !node.proximity.isInside ) {
			node.proximity.isInside = true;
			node.proximity.entered.dispatch(node.entity);
		}
	}
	
	private function outside( node:ProximityNode):void {
		if ( node.proximity.isInside ) {
			node.proximity.isInside = false;
			node.proximity.exited.dispatch(node.entity);
		}
	}
}

}
