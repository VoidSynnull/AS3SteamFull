package game.scenes.examples.debugExample
{
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.Think;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.testIsland.drewTest.DrewTest;
	import game.util.CharUtils;
	
	import org.osflash.signals.Signal;
	
	public class DebugExample extends PlatformerGameScene
	{
		//Easier access to player components.
		private var dialog:Dialog;
		private var spatial:Spatial;
		
		//Trying to break the game with a Tween. Not so successful.
		private var tween:TweenMax;
		
		public var signal1:Signal = new Signal(Number);
		public var signal2:Signal = new Signal(Number);
		
		public var value:Number = 20;
		public var text:String = "Looks like you're trying to use a breakpoint. Do you need any help with that?";
		
		public function DebugExample()
		{
			super();
		}
		
		override public function destroy():void
		{
			this.dialog = null;
			this.tween = null;
			
			/**
			 * Only signal1 is being removed. Always make sure to clean up ALL signals.
			 * 
			 * This should include signal2 as well!
			 */
			this.signal1.removeAll();
			this.signal1 = null;
			
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/debugExample/";
			//super.showHits = true;
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.dialog = this.player.get(Dialog);
			this.spatial = this.player.get(Spatial);
			
			if(this.shellApi.checkEvent("TweenMax"))
			{
				this.shellApi.removeEvent("TweenMax");
				this.dialog.say("So, TweenMax moved me here... from a different Scene! I need an adult...");
			}
			
			this.setupSignals();
			
			this.setupButtons();
		}
		
		private function setupSignals():void
		{
			for(var i:int = 1; i <= 3; i++)
			{
				this.signal1.add(this["handler" + i]);
				this.signal2.add(this["handler" + i]);
			}
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xFFFFFF);
			labelFormat.align = TextFormatAlign.CENTER;
			
			//Top row of buttons
			ButtonCreator.createButtonEntity(this._hitContainer["stack"], this, this.stack);
			ButtonCreator.addLabel(this._hitContainer["stack"], "Crash For\nStack", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity(this._hitContainer["breakpoint"], this, this.breakpoint);
			ButtonCreator.addLabel(this._hitContainer["breakpoint"], "Stop For\nBreakpoint", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity(this._hitContainer["variableScope"], this, this.variableScope);
			ButtonCreator.addLabel(this._hitContainer["variableScope"], "Variable/Scope\nBug", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			//Bottom row of buttons
			ButtonCreator.createButtonEntity(this._hitContainer["signalObject"], this, this.signalObject);
			ButtonCreator.addLabel(this._hitContainer["signalObject"], "Trace Signal\nObject", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity(this._hitContainer["signalArgs"], this, Command.create(this.signalArgs, 5, "A Pretty Sweet String!", new Point()));
			ButtonCreator.addLabel(this._hitContainer["signalArgs"], "Trace Signal\nArgs", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity(this._hitContainer["tweenMax"], this, this.tweenMax);
			ButtonCreator.addLabel(this._hitContainer["tweenMax"], "TweenMax Bug!", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		
		/**
		 * Spatial hasn't been initialized intentionally in order to crash the Scene and bring up the stack. The stack shows a list
		 * of relevant function calls that lead up to the point of the crash. This can help you figure out why the crash happened,
		 * what values the functions and variables were expecting, etc.
		 */
		private function stack(button:Entity):void
		{
			var spatial:Spatial;
			spatial.x = 1;
		}
		
		/**
		 * This breakpoint will be triggered once the player presses the "Breakpoint" button. Breakpoints are useful
		 * for viewing the state of the game and its values at a specific point during runtime.
		 * 
		 * Now would be a good time to take a look at the Variables Window.
		 */
		private function breakpoint(button:Entity):void
		{
			//<--- Oh look, a mystical breakpoint!
			this.shellApi.log("Let's take a break... point.", this);
			trace("Let's take a break... point.");
		}
		
		/**
		 * If a Signal is dispatching values to your Function and you don't know what the Class of the values are,
		 * you can set the Class of your Function's values to Object and "trace(object)" to find out its Class type.
		 */
		private function signalObject(object:Object):void
		{
			this.shellApi.log(object, this);
			trace(object);
			
			CharUtils.setAnim(this.player, Think);
			
			this.dialog.say("What is this?! Oh, that's right, it's an " + object + "!");
			this.dialog.complete.addOnce(endThinking);
		}
		
		/**
		 * Alternatively, if a Signal is dispatching many (and a possibly unknown amount of) values to your Function,
		 * you can catch all of the arguments with "function(...args)" and "trace(args)" to get a list of all of them.
		 */
		private function signalArgs(...args):void
		{
			this.shellApi.log(args, this);
			trace(args);
			
			var string:String = args.join(", ");
			
			CharUtils.setAnim(this.player, Think);
			
			this.dialog.say("What are all of these?! Let's see, we've got... " + string + "!");
			this.dialog.complete.addOnce(endThinking);
		}
		
		/**
		 * Using TweenMax directly is dangerous. Usually, tweening Objects while a Scene is being destroyed will cause crashes.
		 * However, I seem to be bad at making bugs intentionally.
		 * 
		 * Instead, I've managed to move the player's Spatial in a different Scene, long AFTER the current
		 * Scene has been destroyed. This is not a feature. This shouldn't happen. Always try to use the Tween
		 * component to tween an Object, since it gets cleaned up automatically. If that isn't possible, always
		 * remember to "kill()" any TweenMax tweens.
		 */
		private function tweenMax(button:Entity):void
		{
			var clip:MovieClip = this._hitContainer["house"];
			this.tween = new TweenMax(clip, 1.5, {value:clip.x - 200, onComplete:this.breakTheGame});
			
			this.shellApi.completeEvent("TweenMax");
			this.shellApi.loadScene(DrewTest);
		}
		
		private function breakTheGame():void
		{
			//Moving in a different Scene?  WHAT IS GOING ON?!
			this.player.get(Spatial).x += 300;
		}
		
		/**
		 * Flash Builder is a powerful tool. But sometimes it's not very intuitive. Actionscript acknowledges variables created
		 * within a Function's scope, but it's not too aware of when a variable has ACTUALLY been declared and/or initialized.
		 * Somehow, FB is able to realize that "string" is a variable even before it's declared, which is a little scary.
		 * 
		 * This can lead to null object reference crashes with Objects and their values due to conditionals like this one, where
		 * a value of an Object is only being set in a conditional, but there is an attempt to get a value that's null elsewhere.
		 * 
		 * If you're getting a null object reference, make sure your variables are in scope and that they've actually been
		 * initialized somewhere.
		 */
		private function variableScope(button:Entity):void
		{
			CharUtils.setAnim(this.player, Think);
			
			var actualString:String = "A Pretty Sweet String!";
			
			trace(string = "!@#$");
			this.shellApi.log(string, this);
			
			if(false)
			{
				//The function will never get here, and yet FB thinks having 'string' before it's even declared is okay. Whu?
				var string:String = actualString;
				trace(string);
			}
			
			this.dialog.say("Funny thing, 'string's value is '" + string + "'.");
			this.dialog.complete.addOnce(watchScope);
		}
		
		private function watchScope(data:DialogData):void
		{
			this.dialog.say("That's all fine and wonderful, but... 'String' hasn't been declared in code yet. Watch your variable scope.");
			this.dialog.complete.addOnce(endThinking);
		}
		
		private function endThinking(...args):void
		{
			CharUtils.stateDrivenOn(this.player);
		}
		
		private function handler1(number:Number):void
		{
			
		}
		
		private function handler2(number:Number):void
		{
			
		}
		
		private function handler3(number:Number):void
		{
			
		}
	}
}