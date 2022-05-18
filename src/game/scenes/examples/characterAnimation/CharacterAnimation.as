package game.scenes.examples.characterAnimation{
	import com.greensock.easing.Bounce;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.StretchSquash;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Crowbar;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Disco;
	import game.data.animation.entity.character.Hammer;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.RobotDance;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Sit;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.TimelineUtils;
	
	public class CharacterAnimation extends PlatformerGameScene
	{
		public function CharacterAnimation()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/characterAnimation/";
			
			super.init(container);
		}

		override public function loaded():void
		{
			setupExampleButtons();
			
			super.loaded();
		}
		
		private function setupExampleButtons():void
		{
			var btnClip:MovieClip;
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			btnClip = MovieClip(super._hitContainer).btn1;
			ButtonCreator.createButtonEntity( btnClip, this, setAnimation );
			ButtonCreator.addLabel( btnClip, "Set Animation", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			btnClip = MovieClip(super._hitContainer).btn2;
			ButtonCreator.createButtonEntity( btnClip, this, viewingLabels );
			ButtonCreator.addLabel( btnClip, "Viewing Labels", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_text = MovieClip(super._hitContainer).textBox.tf as TextField	// simple on/off movieclip to demonstrate example
			
			btnClip = MovieClip(super._hitContainer).btn3;
			ButtonCreator.createButtonEntity( btnClip, this, usingLabels );
			ButtonCreator.addLabel( btnClip, "Using Labels", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_triggerLight = MovieClip(super._hitContainer).lightGreen1;	// simple on/off movieclip to demonstrate example
			_triggerLight.gotoAndStop(1);
			
			btnClip = MovieClip(super._hitContainer).btn4;
			ButtonCreator.createButtonEntity( btnClip, this, layeringAnimations );
			ButtonCreator.addLabel( btnClip, "Layer Animation", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn5;
			ButtonCreator.createButtonEntity( btnClip, this, stretchAndSquash );
			ButtonCreator.addLabel( btnClip, "Stretch Squash", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			var whiteHead:Entity = super.getEntityById("whiteHead");
			CharUtils.setAnim( whiteHead, Hammer );
			
			btnClip = MovieClip(super._hitContainer).btn6;
			ButtonCreator.createButtonEntity( btnClip, this, playingAnimation );
			ButtonCreator.addLabel( btnClip, "Playing", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_playingLight = MovieClip(super._hitContainer).lightGreen2;	// simple on/off movieclip to demonstrate example
			_playingLight.gotoAndStop(2);
			
			btnClip = MovieClip(super._hitContainer).btn7;
			ButtonCreator.createButtonEntity( btnClip, this, reverseAnimation );
			ButtonCreator.addLabel( btnClip, "Reverse", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_reverseLight = MovieClip(super._hitContainer).lightGreen3;	// simple on/off movieclip to demonstrate example
			_reverseLight.gotoAndStop(1);
			
			btnClip = MovieClip(super._hitContainer).btn8;
			ButtonCreator.createButtonEntity( btnClip, this, setAnimAndGoTo );
			ButtonCreator.addLabel( btnClip, "Set & GoTo", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn9;
			ButtonCreator.createButtonEntity( btnClip, this, setAnimAndStop );
			ButtonCreator.addLabel( btnClip, "Set & Stop", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn10;
			ButtonCreator.createButtonEntity( btnClip, this, play );
			ButtonCreator.addLabel( btnClip, "Play", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////// CHARACTER ANIMATION EXAMPLES //////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Character animation, the heart and sole every Poptropican.
		 * I'm not going to lie to you, the character animation systems are complex.
		 * There are a lot of moving parts and a lot of classes involved.
		 * This example is not going to explain how all those classes work,
		 * that is better suited for a visual diagram.
		 * 
		 * Instead these examples we will focus on what we can do with the character, 
		 * leaving the nuts and bolts systems out of it.
		 * 
		 * So let's get started
		 */
		
		/**
		 * EXAMPLE 1 : Setting an Animation
		 * 
		 * Setting ca haracter's animation manually is pretty straight forward via the CharUtils.setAnim method.
		 * @param	button
		 */
		private function setAnimation( button:Entity ):void
		{
			// get a reference to first npc
			var redHead:Entity = super.getEntityById("redHead");
			
			/**
			 * Use the CharUtils setAnim method to manually set a characters animation.
			 * We set a duration so the animation will only play for 60 frames before reverting to 'auto'.
			 * If you've done the animationSequencing example, you'll recognize duration as it uses the same system.
			 */
			//CharUtils.setAnim( redHead, Crowbar, false );
			
			CharUtils.setAnim( redHead, Celebrate, false );
			CharUtils.setAnim( super.player, Celebrate, false );
			
			/**
			 * setAnim : Manually changes a character's animation. 
			 * @param	entity - the character you are applying the animation to, must contain the necessary components
			 * @param	animClass - the animation Class you are applying
			 * @param	waitForEnd - if true the new animation will not take effect until the current one ends.
			 * @param	priority - the animation slot you are changing, unless you are layering animations it will be 0.
			 * @param	duration - set a aduration for the applied animation, it set animation will play for that amount of frames.
			 */	
		}

		/**
		 * EXAMPLE 2 : Animation Labels
		 * 
		 * In many cases we may want to know when an animation has reached a certian frame.
		 * We can listen for these labels using the Timeline component's labelReached Signal.
		 * In this example we'll display each label when it is reached so we can see what is happening when
		 */
		private function viewingLabels( button:Entity ):void
		{
			var orangeHead:Entity = super.getEntityById("orangeHead");
			_triggerLight.gotoAndStop(1);	//turn off our light, which we use in the example
			
			CharUtils.setAnim( orangeHead, Crowbar );

			// get the Timeline component from the character
			var timeline:Timeline = orangeHead.get(Timeline) as Timeline;
			
			// add listener to the Timeline's labelReached Signal.  
			// This Signal dispatches everytime it reaches a label and passes the label String as a parameter.
			timeline.labelReached.add( onLabelReached );
		}
		
		/**
		 * When a label is reached it will call our handler & pass the lable string as a parameter.
		 * We'll then display this label using the textBox created in setup.
		 * @param	label
		 */
		private function onLabelReached( label:String ):void
		{
			// when a label is reached we'll display it the text box, it will remain there until the next label
			_text.text = label;
			
			// when we reach the last frame lwe remove our listener.
			if ( label == Animation.LABEL_ENDING )
			{
				var orangeHead:Entity = super.getEntityById("orangeHead");
				var timeline:Timeline = orangeHead.get(Timeline) as Timeline;
				timeline.labelReached.remove( onLabelReached );
			}
		}
		
		/**
		 * EXAMPLE 3 : Handling Labels
		 * 
		 * When we want a particular frame label to trigger something 
		 * we can setup a handler to listen just for that label. 
		 */
		private function usingLabels( button:Entity ):void
		{
			var greenHead:Entity = super.getEntityById("greenHead");
			_triggerLight.gotoAndStop(1);	//turn off our light, which we use in the example
			
			CharUtils.setAnim( greenHead, Crowbar );
			
			// Add a handler for when the Crowbar animation reaches label named "trigger"
			TimelineUtils.onLabel( greenHead, "trigger", onTriggeredReached );
			/**
			 * The TimelineUtils.onLabel method adds handler function for when the supplied label is reached.
			 * The longhand form of this would be:
				 * 
				 * var timeline:Timeline = orangeHead.get( Timeline ) as Timeline;
				 * var labelListeningFor:String = "trigger";
				 * var labelHandler:LabelHandler = new LabelHandler( labelListeningFor, onTriggeredReached, true );
			     * timeline.labelHandlers.push( labelHandler );
				 * 
			 */
		}
		
		/**
		 * This function will be called when the animation reaches a frame with a label with value "trigger".
		 */
		private function onTriggeredReached():void
		{
			// turn green light on when "trigger" label is reached.
			_triggerLight.gotoAndStop(2);
			
			/**
			 * As we see this function is called when the Crowbar animation reaches a particular frame.
			 * This is how we trigger behavior that needs to correspond to a particular frame of an animation.
			 */
		}
		
		/**
		 * EXAMPLE 4 : Layering Animations
		 * 
		 * A new feature is the ability to layer animations, this is possible using the animation slots.
		 * The idea of animation slots is that you can have multipe animations acting on one character at the same time.
		 * Every character has at least 1 aniamtion slot with a priority 0.
		 * Additional animation slots will be played 'over' any animation slots with a lower priority.
		 * Let's look at the example fo rfurthe explanation
		 */
		private function layeringAnimations( button:Entity ):void
		{
			var blueHead:Entity = super.getEntityById("blueHead");
			var rigAnim:RigAnimation;
			
			if( !_toggle )
			{
				
				
				// we set our normal animation, which is at slot 0, to Run
				CharUtils.setAnim( blueHead, Run, false );
				
				// to layer animations, we will need another animation slot
				
				// first let's check if there is already an RigAnimation in the next slot, which would be 1.
				rigAnim = CharUtils.getRigAnim( blueHead, 1 );
				
				// if there isn't an animation slot above our default then we add a new animation slot
				if ( rigAnim == null )
				{
					// we create a new animation slot Entity using the AnimationSlotCreator
					// if a slot priority isn't specified it will add one to the next available slot
					var animationSlot:Entity = AnimationSlotCreator.create( blueHead );
					
					// now that we have a new animation slot, let's get it's RigAnimation so we can set it later.
					rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
				}
				
				// We set the RigAnimation's next animation to be Disco
				rigAnim.next = Disco;
				
				// We then specify which parts the animation should apply to.
				// We want the characetr to run while he does the Cabbage, 
				// so have the animation apply to every part but the feet.
				rigAnim.addParts( 	CharUtils.HAND_FRONT, CharUtils.HAND_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK, 
									CharUtils.BODY_JOINT, CharUtils.NECK_JOINT, CharUtils.LEG_BACK, CharUtils.LEG_FRONT );
			}
			else
			{
				rigAnim = CharUtils.getRigAnim( blueHead, 1 );
				rigAnim.manualEnd = true;
			}
			
			_toggle = !_toggle;
		}
		
		private function stretchAndSquash( button:Entity ):void
		{
			var purpleHead:Entity = super.getEntityById("purpleHead");

			var morph:StretchSquash = MotionUtils.addStretchSquash( purpleHead, this ); 
			morph.inverseRate = .5;
			morph.scalePercent = .2;
			morph.duration = 1;
			morph.transition = Bounce.easeOut;
			morph.squash();
			morph.complete.addOnce( returnOriginal )
		}
		
		private function returnOriginal():void
		{
			var purpleHead:Entity = super.getEntityById("purpleHead");
			
			var morph:StretchSquash = purpleHead.get( StretchSquash ) as StretchSquash;
			morph.transition = Bounce.easeOut;
			morph.original();
		}
		
		/**
		 * Playing and stopping an animation is easy, 
		 * just set the timeline component's playing var to true or false.
		 * @param	button
		 */
		private function playingAnimation( button:Entity ):void
		{
			var whiteHead:Entity = super.getEntityById("whiteHead");

			var timeline:Timeline = CharUtils.getTimeline( whiteHead );
			timeline.playing = !timeline.playing;
			
			if ( timeline.playing )
			{
				_playingLight.gotoAndStop(2);
			}
			else
			{
				_playingLight.gotoAndStop(1);
			}
		}
		
		/**
		 * You can set your timeline to run in reverse, by setting Timeline.reverse to true.
		 * Reversing an animation will often have odd behavior due to stop and gotoAndPlay,
		 * and will likely require some further handling to get the desire effect.
		 * @param	button
		 */
		private function reverseAnimation( button:Entity ):void
		{
			var whiteHead:Entity = super.getEntityById("whiteHead");

			var timeline:Timeline = CharUtils.getTimeline( whiteHead );
			timeline.reverse = !timeline.reverse;
			
			if ( timeline.reverse )
			{
				_reverseLight.gotoAndStop(2);
			}
			else
			{
				_reverseLight.gotoAndStop(1);
			}
		}
		
		/**
		 * Sometime you may want to set a new animation, 
		 * and have it go directly to a frame.
		 * @param	button
		 */
		private function setAnimAndGoTo( button:Entity ):void
		{
			var blackHead:Entity = super.getEntityById("blackHead");
			
			// first set the animation
			CharUtils.setAnim( blackHead, Sit );
			
			// then get the timeline and call a gotoAndPlay, gotoAndStop
			Timeline( blackHead.get(Timeline)).gotoAndPlay("loop");
			
			// That's all there is too it, 
			// You can also use a frame index instead of a label.
		}
		
		/**
		 * When you set an animation it starts playing by default.
		 * You may want to set an animation, but have it stop on the first frame.
		 * @param	button
		 */
		private function setAnimAndStop( button:Entity ):void
		{
			var blackHead:Entity = super.getEntityById("blackHead");
			
			// first set the animation
			CharUtils.setAnim( blackHead, Hammer );
			
			// then get the timeline and call a stop
			Timeline( blackHead.get(Timeline)).stop();
			
			/**
			 * That's all there is too it.
			 * In this case you do not want to set timeline.playing to false,
			 * as this will get set back to true when the animation loads.
			 * By calling stop(), you actually add a stop frame event, 
			 * this event then gets processed once the new animation starts.
			 */
		}
		
		private function play( button:Entity ):void
		{
			// If an animation is stop, just set playing to true to start it again.
			var blackHead:Entity = super.getEntityById("blackHead");
			
			// then get the timeline and call a stop
			Timeline( blackHead.get(Timeline)).playing = true;
		}

		private var _toggle:Boolean = false;
		private var _triggerLight:MovieClip;
		private var _playingLight:MovieClip;
		private var _reverseLight:MovieClip;
		private var _text:TextField;
	}
}