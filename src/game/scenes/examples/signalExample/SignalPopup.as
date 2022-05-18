package game.scenes.examples.signalExample
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.AttackRun;
	import game.data.animation.entity.character.Cabbage;
	import game.data.animation.entity.character.Disco;
	import game.data.animation.entity.character.SitSleepLoop;
	import game.data.animation.entity.character.KeyboardTyping;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	public class SignalPopup extends Popup
	{
		/**
		 * The Signals lie within the popup. When the popup is instantiated, the scene's functions will be added
		 * to their list of functions that are to be dispatched.
		 */
		public var changeHair:Signal;
		public var teleport:Signal;
		public var animation:Signal;
		
		public function SignalPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			
			/**
			 * The changeHair Signal will dispatch an uint of the hair color.
			 */
			changeHair = new Signal(uint);
			
			/**
			 * The teleport Signal will dispatch with no params. The scene doesn't need any information other than
			 * knowing it was triggered.
			 */
			teleport = new Signal();
			
			/**
			 * The animation Signal will dispatch the class of the animation to be applied to the NPC
			 */
			animation = new Signal(Class);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/examples/signalExample/signalPopup/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("signalPopup.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.screen = super.getAsset("signalPopup.swf", true) as MovieClip;
			super.layout.centerUI(super.screen.content);
			super.loadCloseButton();
			super.loaded();
			
			/**
			 * Sets up the buttons that will send information back to the scene.
			 * This finds the MovieClip of the button in the popup, and tells the button what
			 * function to send to the button's Signal.
			 */
			setupButton("hairButton", handleChangeHair);
			setupButton("teleportButton", handleTeleport);
			setupButton("animationButton", handleAnimation);
		}
		
		private function setupButton(name:String, handler:Function):void
		{
			var clip:MovieClip;
			var button:Entity;
			
			clip = MovieClip(MovieClip(super.screen.content).getChildByName(name));
			
			button = ButtonCreator.createButtonEntity(clip, this);
			var interaction:Interaction = button.get(Interaction);
			interaction.clickNative.add(handler);
			
			button.add(new Id(name));
			this.addEntity(button);
		}
		
		/**
		 * When the hairButton is pressed, the button's Signal will execute this function,
		 * and it will dispatch a random hair color back to the scene.
		 */
		private function handleChangeHair(event:Event):void
		{
			//Pick a random color and dispatch it
			changeHair.dispatch(Math.floor(Math.random() * 0xFFFFFF ));
			
			//Close the popup
			this.close();
		}
		
		/**
		 * When the teleportButton is pressed, the button's Signal will execute this function,
		 * and it will only tell the scene that something has happened. No params are sent.
		 */
		private function handleTeleport(event:Event):void
		{
			//Make teleporting happen...
			teleport.dispatch();
			
			//Close the popup
			this.close();
		}
		
		/**
		 * When the animationButton is pressed, the button's Signal will execute this function,
		 * and it will dispatch an animation back to the scene for the NPC to do.
		 */
		private function handleAnimation(event:Event):void
		{
			//Make an array of animations that all have a "loop" frame label in them somewhere
			var array:Array = new Array(SitSleepLoop, Cabbage, Disco, KeyboardTyping, AttackRun);
			
			//Pick one at random and dispatch it
			var aClass:Class = array[Math.floor( Math.random() * array.length )];
			animation.dispatch( aClass );
			
			//Close the popup
			this.close();
		}
	}
}
