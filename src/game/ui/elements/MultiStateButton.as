package game.ui.elements {

import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.events.Event;

import game.creators.ui.ButtonCreator;
import game.data.ui.ButtonSpec;

	/**
	 * Implements a clickable "action" button which can have
	 * several states: UP, OVER, DOWN, DISABLED. The images
	 * for these states are supplied by a given MovieClip which
	 * identifies the appropriate image for each state with
	 * predefined labels: 'up', 'over', 'down', and 'disabled',
	 * respectively. If no 'disabled' label is present, a stock
	 * effect of 50% opacity will be applied.
	 * 
	 * @author Rich Martin
	 * 
	 */	
	public class MultiStateButton extends StandardButton {

		

		public static const INIT:String								= 'init';
		public static const DISABLED:String							= 'disabled';
		
		/**
		 * Uses the <code>ButtonCreator</code> to instantiate a new
		 * <code>MultiStateButton</code> instance, initialized from the relevant
		 * fields of a <code>ButtonSpec</code>. 
		 * @param spec	A <code>ButtonSpec</code> filled out with configuration options
		 * @return A <code>MultiStateButton</code> configured from a <code>ButtonSpec</code>
		 * @see game.data.ui.ButtonSpec
		 * @see game.creators.ui.ButtonCreator
		 */		
		public static function instanceFromButtonSpec(spec:ButtonSpec):MultiStateButton {
			var newButton:MultiStateButton = ButtonCreator.createMultiStateButton(spec.displayObjectContainer, spec.clickHandler, spec.container, spec.parentGroup, spec.interactions);
			if (spec.pressAction != null) {
				BasicButton.addPressAction(newButton, spec.pressAction);
			}
			
			return newButton;
		}

		protected var enabled:Boolean = true;
		protected var depressed:Boolean = false;
		protected var frameLabels:Vector.<String>;

		public function MultiStateButton(faces:MovieClip=null) {
			frameLabels = new <String>[];
			this.faces = faces;
			state = INIT;
		}

		//// ACCESSORS ////

		public function get faces():MovieClip { return displayObject as MovieClip; }
		public function set faces(newFaces:MovieClip):void {
			if (null == newFaces) {
				return;
			}
			displayObject = newFaces;
			newFaces.mouseChildren = false;
			for each (var flabel:FrameLabel in newFaces.currentLabels) {
				frameLabels.push(flabel.name);
			}
			state = StandardButton.UP;
		}

		public function get selected():Boolean { return depressed; }
		public function set selected(flag:Boolean):void {
			depressed = flag;
			state = (flag ? StandardButton.OVER : StandardButton.UP);
		}

		public override function set state(newState:String):void {
			if (newState == _state) {
				return;
			}
			switch (newState) {
				case INIT:
					_state = INIT;
					return;
				case DISABLED:
				case StandardButton.UP:
				case StandardButton.OVER:
				case StandardButton.DOWN:
					showState(newState);
					break;
				default:
					trace("MultiStateButton can't show unknown state:", newState);
					break;
			}
			_state = newState;
			enabled = (newState != DISABLED) && (newState != INIT);
			displayObject.mouseEnabled = enabled;
		}

		//// PUBLIC METHODS ////

		public override function overHandler(e:Event):void {
			if (enabled) {
				state = StandardButton.OVER;
			}
		}

		public override function outHandler(e:Event):void {
			if (enabled) {
				state = StandardButton.UP;
			}
		}

		public override function downHandler(e:Event):void {
			if (enabled) {
				state = StandardButton.DOWN;
			}
		}

		public override function upHandler(e:Event):void {
			if (enabled) {
				state = StandardButton.OVER;
			}
		}

		//// INTERNAL METHODS ////

		//// PROTECTED METHODS ////

		protected function showState(btnState:String):void {
			if (btnState == INIT) {
				return;
			}
			if (DISABLED == btnState) {
				var hasDisabledFace:Boolean = frameLabels.indexOf(DISABLED) > -1;
				if (hasDisabledFace) {
					(displayObject as MovieClip).gotoAndStop(btnState);
				} else {
					displayObject.alpha = 0.5;
				}
			} else {
				displayObject.alpha = 1.0;
				(displayObject as MovieClip).gotoAndStop(btnState);
			}
		}

		//// PRIVATE METHODS ////

	}
}
