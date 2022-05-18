package game.ui.elements 
{
	public class BasicButton extends UIElement 
	{
		import engine.creators.InteractionCreator;
		import engine.util.Command;

		import game.creators.ui.ButtonCreator;
		import game.data.ui.ButtonSpec;

		/**
		 * Uses the <code>ButtonCreator</code> to instantiate a new
		 * <code>BasicButton</code> instance, initialized from the relevant
		 * fields of a <code>ButtonSpec</code>. 
		 * @param spec	A <code>ButtonSpec</code> filled out with configuration options
		 * @return A <code>BasicButton</code> configured from a <code>ButtonSpec</code>
		 * @see game.data.ui.ButtonSpec
		 * @see game.creators.ui.ButtonCreator
		 */		
		public static function instanceFromButtonSpec(spec:ButtonSpec):BasicButton {
			var newButton:BasicButton = ButtonCreator.createBasicButton(spec.displayObjectContainer, spec.interactions, spec.parentGroup, spec.clickHandler);
			if (spec.pressAction != null) {
				BasicButton.addPressAction(newButton, spec.pressAction);
			}
			
			return newButton;
		}

		// TODO: make this more flexible using inner args
		/**
		 * Uses the <code>InteractionCreator</code> to install a callback
		 * <code>Function</code> which will be automatically invoked whenever the
		 * button dispatches a <code>MOUSE_DOWN NativeSignal</code>.
		 * A new <code>NativeSignal</code> will be created if necessary.
		 * @param btn	The <code>BasicButton</code> which will receive the <code>pressAction</code>
		 * @param action	The <code>pressAction</code> to install
		 * @see engine.creators.InteractionCreator
		 */		
		public static function addPressAction(btn:BasicButton, action:Function):void {
			btn.pressAction = action;
			if (null == btn.down) {
				InteractionCreator.addToUIElement(btn, [InteractionCreator.DOWN]);
			}
			btn.down.add(Command.create(btn.pressAction));
		}

		protected var pressAction:Function;		// if initialized, this function will be called whenever a press (MOUSE_DOWN) occurs on the displayObject

		public function BasicButton() {}
		
		/** Holds a value associated with the button, value can any type of object */
		public var value:*;
	}
}