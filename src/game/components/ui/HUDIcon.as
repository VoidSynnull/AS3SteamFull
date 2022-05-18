package game.components.ui {

import ash.core.Component;
	
public class HUDIcon extends Component {
	
	public function HUDIcon() {
	}
	
	public static const MIN_SCALE:Number = 0.3;

	public var isSpillStart:Boolean;			// initialization flag for spill, resets parameters
	public var isRetractStart:Boolean;			// initialization flag for retract, resets parameters
	
	public var index:int;				// horizontal position in hud, fartherest left is 0
	public var ground:Number;			// 
	public var startX:Number;			// start x postion, equal to position of hud button
	public var targetX:Number;			// final x position once button is fully unfurled

	public var vyStart:Number = 0;			// starting y velocity, use to make buttons 'bounce'
	public var retractYAccel:Number = 0;	// acceleration during retract transition
	public var maxDeltaX:Number;			// final x position once button is fully unfurled
	
	public var hidden:Boolean = false;		// flag to permanently hide a hud button, will cause owning entity to remain hidden
	public var disabled:Boolean = false;	// flag to permanently disable a hud button, will cause owning entity to remain inactive
	
	public function calculateVars():void
	{
		this.vyStart = -( 300 - 20 * index );
		this.retractYAccel = 8000 - 70 * index;
		this.maxDeltaX = startX - targetX;
	}
}

}
