package game.scenes.mocktropica.cheeseExterior {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.MotionBounds;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.particles.emitter.Rain;
	import game.scene.template.CharacterGroup;
	import game.scenes.mocktropica.cheeseExterior.components.GlitchSign;
	import game.scenes.mocktropica.cheeseExterior.systems.GlitchSignSystem;
	import game.scenes.mocktropica.shared.*;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Steady;
	
	public class CheeseExterior extends MocktropicaScene {

		// Security guard entity.
		private var guard:Entity;
		private var mockEvents:MocktropicaEvents;
		private var _narfCreator:NarfCreator;
		private var pets:Vector.<Entity>;

		/**
		 * Pixelates the cows.
		 */
		//private var pixelFilter:DisplacementMapFilter;

		/**
		 * Guard starts off hating the player until adjusted, apparently.
		 */
		private var badAttitude:Boolean = true;

		private var glitched:Boolean;

		public function CheeseExterior() {

			super();
		} 

		// pre load setup
		override public function init(container:DisplayObjectContainer=null ):void {

			super.groupPrefix = "scenes/mocktropica/cheeseExterior/";
			super.init(container);

		} //

		// initiate asset load of scene specific assets.
		override public function load():void {

			super.load();

		} //

		// all assets ready
		override public function loaded():void {

			super.loaded();			
			this.guard = this.getEntityById( "guard" );			
			this.mockEvents = this.events as MocktropicaEvents;
			DisplayUtils.convertToBitmap( this._hitContainer["sidewalk"] );
			this.addSystem( new GlitchSignSystem(), SystemPriorities.update );
			
			// If it should be raining turn the rain effect on
			if(super.shellApi.checkEvent(mockEvents.SET_RAIN)) {
				
				var rain:Rain = new Rain();
				rain.init(new Steady(50), new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight), 2);
				EmitterCreator.createSceneWide(this, rain);
			}
			
			if(super.shellApi.checkEvent(mockEvents.BOY_LEFT_MAIN_STREET_CHEESE) && !super.shellApi.checkEvent(mockEvents.BOY_LEFT_CHEESE_EXTERIOR)) {
				// after the boy has a pet on mainstreet show him here
				loadPets();
			} else {
				var boy:Entity = this.getEntityById("boy");
				this.removeEntity(boy);
			}

			// Actually checking here if the guard has a "bad attitude"
			if ( this.shellApi.checkEvent( this.mockEvents.IS_HAPPY ) ) {

				// change guard dialog.
				SkinUtils.setSkinPart( this.guard, SkinUtils.MOUTH, "1", true );
				SkinUtils.setEyeStates(this.guard, "open", null, true);


			} else {

				this.disableFactoryDoor();

			} //
			
			if ( !this.shellApi.checkEvent( this.mockEvents.DEVELOPER_RETURNED ) ) {
				
				this.glitched = true;
				this.initSigns( true );
				
			} else {
				
				this.initSigns( false );
				
			} // end-if.
			
			this.initCows();
		
			if ( this.shellApi.checkEvent( this.mockEvents.SET_NIGHT ) ) {

				AudioUtils.play(this, SoundManager.AMBIENT_PATH + "nighttime_crickets.mp3", 1, true);
			} else {

				this.removeEntity( this.getEntityById("overlayNight") );
				//SimpleUtils.hideEntity( this.getEntityById("overlayNight") );

			} // end-if.
			
			if ( this.shellApi.checkEvent( this.mockEvents.SET_RAIN ) ) {

			} else {

				this.removeEntity( this.getEntityById("overlayRain") );
				//SimpleUtils.hideEntity( this.getEntityById("overlayRain") );

			} // end-if.

			this.initBuckets();

			if ( this.shellApi.checkHasItem( "curds" ) ) {

				var grp:AchievementGroup = new AchievementGroup( this );
				this.addChildGroup( grp );
				grp.completeAchievement( this.mockEvents.ACHIEVEMENT_SCENE_STEALER );

			} //

		} //
		
		private function loadPets():void {

			_narfCreator = new NarfCreator(this, super.getGroupById("characterGroup") as CharacterGroup, this._hitContainer);
			pets = new Vector.<Entity>();
			
			var boy:Entity = this.getEntityById("boy");			
			for(var i:int = 0; i < 6; i++)
			{
				_narfCreator.create(boy, narfLoaded);
			}
			
			var boyDialog:Dialog = getEntityById("boy").get(Dialog);
			
			boyDialog.sayById("boy_multiplying");
			boyDialog.complete.addOnce(boyDoneTalking);
			SceneUtil.lockInput(this);
			CharUtils.lockControls(this.player);
		}
		
		private function narfLoaded(entity:Entity):void
		{
			this._hitContainer.setChildIndex(Display(this.player.get(Display)).displayObject, this._hitContainer.numChildren - 1);
			pets.push(entity);
		}
		
		private function boyDoneTalking(dialogData:DialogData):void
		{
			var boy:Entity = getEntityById("boy");
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM(boy);
			
			CharacterMotionControl(boy.get(CharacterMotionControl)).maxVelocityX = 400;
			SceneInteraction(boy.get(SceneInteraction)).reached.removeAll();
			MotionBounds(boy.get(MotionBounds)).box.left = -600;
			
			CharUtils.followPath(boy, new <Point>[new Point(700, 1640), new Point(-500, 1640)], boyOffScreen);
		}
		
		private function boyOffScreen(entity:Entity):void
		{
			CharUtils.lockControls(this.player, false, false);
			SceneUtil.lockInput(this, false);
			removeEntity(entity);
			
			for each(var pet:Entity in pets)
			{
				removeEntity(pet);
			}
		}
	
		private function initCows():void {

			var i:int = 1;
			var mc:MovieClip = this._hitContainer["cow"+i];

			var pixelator:MovieClip;

			// Note: the size of this filter needs to be as large as the largest frame of all cow animations.
			//var filter:DisplacementMapFilter = PixelationUtils.makePixelFilter( 1*mc.width, 1*mc.height, 12 );

			while ( mc != null ) {

				// two cow frames of slightly? different looking cows.
				if ( Math.random() < 0.5 ) {
					mc.gotoAndStop( 1 );
				} else {
					mc.gotoAndStop( 2 );
				}

				pixelator = mc.pixelateCow;
				if ( glitched ) {
					pixelator.gotoAndPlay( Math.floor( Math.random()*pixelator.totalFrames )+1 );
					//mc.removeChild( pixelator );
				} else {
					mc.removeChild( pixelator );
				}

				//mc.filters = [filter];

				i++;
				mc = this._hitContainer["cow"+i];

			} //

		} //

		/**
		 * Player tried to leave through factory door. If the guard is angry, this won't work.
		 */
		private function reachedFactoryDoor( interactor:Entity, interactedWith:Entity ):void {

			SimpleUtils.manualSay( this.guard, "beat_it" );

		} //

		private function initSigns( glitched:Boolean=false ):void {

			var signNames:Vector.<String> = new <String>[ "mainSign", "parkingSign", "cowSign", "yodelSign" ];
			var entity:Entity;
			var mc:MovieClip;

			var tl:Timeline;

			for( var i:int = signNames.length-1; i >= 0; i-- ) {

				mc = this._hitContainer[ signNames[ i ] ];

				entity = TimelineUtils.convertClip( mc, this );
				tl = entity.get( Timeline );

				if ( glitched ) {
					entity.add( new GlitchSign() );
				} else {
					tl.gotoAndStop( 1 );
				}

			} // end for-loop.

		}

		/**
		 * Two buckets: bucket1, bucket2, they have flowers: cheeseFlower1, cheeseFlower2
		 */
		private function initBuckets():void {

			var bucket:Entity;
			//var flower:Entity;
			var mc:MovieClip;

			//var interaction:Interaction;
			var si:SceneInteraction;

			for( var i:int = 1; i <= 2; i++ ) {

				if ( this.glitched == false ) {

					// assume the flowers are only for the glitches.
					this._hitContainer.removeChild( this._hitContainer["cheeseFlower"+i] );
					continue;

				} //

				mc = this._hitContainer["bucket"+i];
				mc.flower = this._hitContainer["cheeseFlower"+i];
				mc.flower.visible = false;

				bucket = EntityUtils.createSpatialEntity( this, this._hitContainer["bucket"+i] );

				si = new SceneInteraction();
				bucket.add( new Id( "bucket"+i ) );
				bucket.add( si, SceneInteraction );

				si.reached.add( reachedBucket );

				InteractionCreator.addToEntity( bucket, [ InteractionCreator.UP, InteractionCreator.DOWN, InteractionCreator.CLICK ] );

				ToolTipCreator.addToEntity( bucket );

			} // for-loop.

		} //

		private function reachedBucket( interactor:Entity, interacted:Entity ):void {

			var flower:MovieClip = ( interacted.get( Display ) as Display ).displayObject["flower"];
			if ( flower ) {
				flower.visible = !flower.visible;
			}

		} //

		/**
		 * Factory door is only enabled when the guard is 'happy'
		 */
		private function disableFactoryDoor():void {

			var factoryDoor:Entity = this.getEntityById( "doorCheeseInterior" );

			var si:SceneInteraction = factoryDoor.get( SceneInteraction );
			si.reached.removeAll();
			si.reached.add( reachedFactoryDoor );

			// override the scene interaction or whatever so you can't go through the door.

		} //
		
		private var _events:MocktropicaEvents;

	} // class

}
