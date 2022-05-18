package game.scenes.virusHunter.joesCondo.classes {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.Grief;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterGroup;
	import game.ui.popup.Popup;
	import game.util.TimelineUtils;
	
	public class EatingCutScene extends Popup {

		public var popupFileName:String;

		public var useCloseButton:Boolean = false;

		// frame that marks the end of the cutscene.
		public var endFrameLabel:String = "ending";

		public var autoPlay:Boolean = true;

		public var callback:Function;

		// Contains the popup clip's timeline component and runs the timeline, etc.
		private var control:Entity;

		private var charGroup:CharacterGroup;

		/**
		 * Clips containing the bits of food where the chars are stored.
		 */
		private var food1:MovieClip;
		private var food2:MovieClip;
		private var food3:MovieClip;

		private var fakePlayer:Entity;
		private var fakeDisplay:DisplayObjectContainer;

		public function EatingCutScene( fileName:String, filePrefix:String, container:DisplayObjectContainer=null, callback:Function=null ) {

			super( container );

			this.callback = callback;
			this.popupFileName = fileName;

			this.groupPrefix = filePrefix;

		} //

		override public function destroy():void {

			// do any cleanup required in this Group before calling the super classes destroy method
			var tl:Timeline = control.get( Timeline ) as Timeline;
			tl.labelReached.removeAll();

			control = null;
			callback = null;

			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();

		} //

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();

			super.darkenBackground = true;
			super.screenAsset = popupFileName;
			super.init( container );
			super.load();

		}
		
		
		// all assets ready
		override public function loaded():void 
		{
			super.preparePopup();

			this.food1 = super.screen.food1;
			this.food2 = super.screen.food2;
			this.food3 = super.screen.food3;

			this.charGroup = new CharacterGroup();
			this.charGroup.setupGroup( this, this.food1.foodInterior.ship.shipBack );
			this.fakePlayer = this.charGroup.createNpcPlayer( this.onCharLoaded, new AnimationSequence(Grief), new Point(0, 22), CharacterCreator.TYPE_DUMMY );

			this.fakeDisplay = this.fakePlayer.get( Display ).displayObject;

			this.food2.visible = false;
			this.food3.visible = false;
			this.food1.visible = false;

			if ( useCloseButton ) 
			{
				// this loads the standard close button
				super.loadCloseButton();
			}

			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			//super.layout.centerUI(super.screen.content);

			// any entities or systems created within this group will automatically be removed on close.
			control = TimelineUtils.convertClip( super.screen, this );
			var tl:Timeline = control.get( Timeline ) as Timeline;
			stop();

			super.groupReady();
		}

		// call manually if autoPlay = false.
		public function onCharLoaded( ...args ):void 
		{
			var tl:Timeline = control.get( Timeline ) as Timeline;
			tl.labelReached.add( checkLabels );
			tl.playing = true;
		}

		public function stop():void {

			var tl:Timeline = control.get( Timeline ) as Timeline;
			tl.playing = false;

		} //

		private function checkLabels( label:String ):void {

			if ( label == endFrameLabel ) {

				var tl:Timeline = control.get( Timeline ) as Timeline;
				tl.playing = false;
				tl.labelReached.remove( this.checkLabels );

				callback();

			} else if ( label == "startFood1" ) {

				this.food1.visible = true;

			} else if ( label == "startFood3" ) {

				this.food3.foodInterior.ship.shipBack.addChild( this.fakeDisplay );
				this.food3.visible = true;

			} else if ( label == "startFood2" ) {

				this.food2.foodInterior.ship.shipBack.addChild( this.fakeDisplay );
				this.food2.visible = true;

			} //

		} //

	} // class

} // package