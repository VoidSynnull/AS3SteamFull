package game.ui.elements {
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import game.util.MovieClipUtils;
	import game.util.PlatformUtils;
	
/**
 * Implements a clickable "toggle" button which can have
 * several states: UP, OVER, DOWN, DISABLED, SELECTED_UP,
 * SELECTED_OVER, SELECTED_DOWN, SELECTED_DISABLED. The images
 * for these states are supplied by a given MovieClip which
 * identifies the appropriate image for each state with
 * predefined labels: 'up', 'over', 'down', 'disabled',
 * 'selectedUp', 'selectedOver', 'selectedDown', 'selectedDisabled,
 * respectively. If no 'disabled' label
 * is present, a stock effect of 50% opacity will be applied.
 * 
 * @author Rich Martin
 * 
 */	
	public class MultiStateToggleButton extends MultiStateButton {


		public static const SELECTED_UP:String			= 'selectedUp';
		public static const SELECTED_OVER:String		= 'selectedOver';
		public static const SELECTED_DOWN:String		= 'selectedDown';
		public static const SELECTED_DISABLED:String	= 'selectedDisabled';

		/****
			this one is trickier to handle wrt pressActions, so save it for later
			maybe need to revisit the pressAction idea
		****/
		protected var selectedPressAction:Function;
		protected var groupMember:Boolean = false;

		public function MultiStateToggleButton(faces:MovieClip=null) {
			super(faces);
		}

		//// ACCESSORS ////

		public override function set selected(flag:Boolean):void {
			depressed = flag;
			state = (flag ? SELECTED_UP : StandardButton.UP);
		}

		public function set activated(flag:Boolean):void {
			if (flag) {	// enabling
				state = selected ? SELECTED_UP : StandardButton.UP;
			} else {	// disabling
				state = DISABLED;
			}
		}

		public function get grouped():Boolean { return groupMember; }
		public function set grouped(flag:Boolean):void {
			groupMember = flag;
		}

		public override function set state(newState:String):void {
			if (newState == _state) {
				return;
			}
			switch (newState) {
				case INIT:
					_state = INIT;
					return;
				case StandardButton.OVER:
				case SELECTED_OVER:
				case StandardButton.UP:
				case SELECTED_UP:
				case StandardButton.DOWN:
				case SELECTED_DOWN:
				case DISABLED:
					showState(newState);
					break;
				default:
					trace("MultiStateToggleButton can't show unknown state:", newState);
					break;
			}
			if (DISABLED == newState) {
				_state = selected ? SELECTED_DISABLED : DISABLED;
			}  else {
				_state = newState;
			}
			enabled = newState != DISABLED;
			displayObject.mouseEnabled = enabled;
		}

		//// PUBLIC METHODS ////

		public override function overHandler(e:Event):void {
			if (enabled) {
				state = (selected ? SELECTED_OVER : StandardButton.OVER);
			}
		}

		public override function outHandler(e:Event):void {
			if (enabled) {
				state = (selected ? SELECTED_UP : StandardButton.UP);
			}
		}

		public override function downHandler(e:Event):void {
			if (enabled) {
				state = (selected ? StandardButton.DOWN : SELECTED_DOWN);
			}
		}

		public override function upHandler(e:Event):void {
			if (enabled) {
				if (!grouped) {
					selected = ! selected;
				}
				if (PlatformUtils.isMobileOS) {	// no rollover state on mobile, so just go back to up
					outHandler(null);
				} else {
					state = (selected ? SELECTED_OVER : StandardButton.OVER);
				}
			}
		}

		//// INTERNAL METHODS ////

		//// PROTECTED METHODS ////
		
		protected override function showState(btnState:String):void {
			if (btnState == INIT) {
				return;
			}
			if (DISABLED == btnState) {
				var hasDisabledFace:Boolean = frameLabels.indexOf(DISABLED) > -1;
				if (hasDisabledFace) {
					(displayObject as MovieClip).gotoAndStop(selected ? SELECTED_DISABLED : DISABLED);
				} else {
					displayObject.alpha = 0.5;
				}
			} else {
				displayObject.alpha = 1.0;
				if( MovieClipUtils.hasLabel( (displayObject as MovieClip), btnState ) ) {
					(displayObject as MovieClip).gotoAndStop(btnState);
				}
			}
		}

		//// PRIVATE METHODS ////

	}
}
