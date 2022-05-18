package game.scenes.virusHunter.bloodStream {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.anteArm.AnteArm;
	import game.scenes.virusHunter.brain.Brain;
	import game.scenes.virusHunter.condoInterior.classes.UpdateManager;
	import game.scenes.virusHunter.hand.Hand;
	import game.scenes.virusHunter.heart.Heart;
	import game.scenes.virusHunter.joesCondo.creators.ClipCreator;
	import game.scenes.virusHunter.mouthShip.MouthShip;
	import game.scenes.virusHunter.stomach.Stomach;
	
	import org.osflash.signals.Signal;

	public class VirusNavigationPane {

		/**
		 * Using an array to avoid the static initializer cast.
		 */
		static public var sceneNames:Array = [ "Mouth", "Heart", "Brain", "Stomach", "Hand", "Arm" ];

		// apparently you can't load scene by name anymore, you need a scene class.
		static public var sceneClasses:Dictionary;

		public var popupFileName:String;

		public var useCloseButton:Boolean = true;

		private var boundsRect:Rectangle;

		// notification function called when user picks a scene:
		// onSceneSelected( sceneName, sceneClass );
		public var onSceneSelected:Signal;

		private var pane:MovieClip;
		private var group:Group;

		private var buttons:Vector.<Entity>;

		private var selectedClip:MovieClip;
		// quick, easy blink timer for blinking selected nav button.
		private var simpleUpdater:UpdateManager;
		private var blinkTimer:Number;

		public function VirusNavigationPane( paneClip:MovieClip, group:Group ) {

			this.pane = paneClip;
			this.group = group;

			// Obnoxious.
			sceneClasses = new Dictionary();
			sceneClasses[ "Mouth" ] = MouthShip;
			sceneClasses[ "Heart" ] = Heart;
			sceneClasses[ "Arm" ] = AnteArm;
			sceneClasses[ "Brain" ] = Brain;
			sceneClasses[ "Stomach" ] = Stomach;
			sceneClasses[ "Hand" ] = Hand;

			onSceneSelected = new Signal( String, Class, Point );

			init();
			
			var entity:Entity = new Entity();
			group.addEntity( entity );
			
			var audio:Audio = new Audio();
			entity.add( audio );
			
			audio.play( SoundManager.EFFECTS_PATH + HEART_BEAT, true );
			audio.play( SoundManager.EFFECTS_PATH + ENGINE_HUM, true );
		} //

		public function init():void {

			initBackground();

			// center the boundsRects in the viewPort.
			pane.x = -boundsRect.x + 0.5*( group.shellApi.viewportWidth - boundsRect.width );
			pane.y = -boundsRect.y + 0.5*( group.shellApi.viewportHeight - boundsRect.height );

			initNavButtons();

		} //

		private function initNavButtons():void {

			var navButtons:DisplayObjectContainer = pane;

			var clip:MovieClip;
			var entity:Entity;

			var creator:ClipCreator = new ClipCreator( group );

			buttons = new Vector.<Entity>();

			var onlyHand:Boolean = true;
			var ve:VirusHunterEvents = ( this.group as Scene ).events as VirusHunterEvents;
			if ( this.group.shellApi.checkEvent( ve.ATTACKED_BY_WBC ) ) {
				onlyHand = false;
			} //
			var noMouth:Boolean = false;
			if ( !this.group.shellApi.checkEvent( ve.GOT_ANTIGRAV ) ) {
				noMouth = true;
			} //

			var sceneName:String;
			for( var i:int = sceneNames.length-1; i >= 0; i-- ) {

				sceneName = sceneNames[i];

				clip = navButtons[ sceneName ];
				clip.gotoAndStop( 1 );

				if ( onlyHand && sceneName != "Hand" ) {

					clip.parent.removeChild( clip );

				} else if ( noMouth && sceneName == "Mouth" ) {			// Messy little addition for mouth check.

					clip.parent.removeChild( clip );

				} else {

					entity = creator.createClickable( clip, this.selectNav, this.onRollOverNav, this.onRollOutNav );

					buttons.push( entity );

				} //

			} //

		} //

		public function disableButtons():void {

			var e:Entity;
			for( var i:int = buttons.length-1; i >= 0; i-- ) {

				e = buttons[i];
				e.remove( Interaction );			// Nuclear option, since we won't need this again.

			} //

		} //

		public function onRollOverNav( e:Entity ):void {

			var clip:MovieClip = e.get( Display ).displayObject as MovieClip;
			clip.gotoAndStop( 2 );
						
			var audio:Audio = e.get( Audio );
			
			if( !audio )
			{
				audio = new Audio();
				e.add( audio );
			}
			
			audio.play( SoundManager.EFFECTS_PATH + PING, false );
		} 

		public function onRollOutNav( e:Entity ):void {

			var clip:MovieClip = e.get( Display ).displayObject as MovieClip;
			clip.gotoAndStop( 1 );
		} //

		public function selectNav( e:Entity ):void {

			selectedClip = e.get( Display ).displayObject as MovieClip;

			// Quick messy fix for sotmach coord. At this time we don't appear to need different coordinates for each scene.
			if ( selectedClip.name == "Stomach" ) {

				onSceneSelected.dispatch( selectedClip.name, sceneClasses[ selectedClip.name ], new Point( 2868, 1097 ) );

			} else {

				onSceneSelected.dispatch( selectedClip.name, sceneClasses[ selectedClip.name ], null );

			} //

			disableButtons();

			blinkTimer = 0;
			simpleUpdater = new UpdateManager( group );
			simpleUpdater.addUpdate( this.blinkSelected );

			
			var audio:Audio = e.get( Audio );
			
			if( !audio )
			{
				audio = new Audio();
				e.add( audio );
			}
			
			audio.play( SoundManager.EFFECTS_PATH + HIGHLIGHT, false );
		} //

		private function blinkSelected( timer:Number ):void {

			blinkTimer += timer;
			if ( blinkTimer >= 0.20 ) {

				blinkTimer -= 0.20;
				if ( selectedClip.currentFrame == 1 ) {
					selectedClip.gotoAndStop( 2 );
				} else {
					selectedClip.gotoAndStop( 1 );
				} //

			} //

		} //

		// bitmap the background.
		protected function initBackground():void {

			var bg:MovieClip = pane["background"];

			if ( bg == null ) {
				return;
			}

			var bounds:MovieClip = pane["popupBounds"];
			if ( bounds == null ) {
				boundsRect = new Rectangle( 0, 0, bg.width, bg.height );
			} else {
				pane.removeChild( bounds );
				boundsRect = new Rectangle( bounds.x, bounds.y, bounds.width, bounds.height );
			} //

			var bm:BitmapData = new BitmapData( boundsRect.width, boundsRect.height, true, 0 );
			bm.draw( bg, new Matrix( 1, 0, 0, 1, bg.x-boundsRect.x, bg.y-boundsRect.y ) );

			var bitmap:Bitmap = new Bitmap( bm );
			bitmap.x = boundsRect.x;
			bitmap.y = boundsRect.y;

			pane.addChildAt( bitmap, 0 );

			// get rid of the background.
			pane.removeChild( bg );

		} //
		
		static private const HIGHLIGHT:String = "engine_speedup.mp3";
		static private const PING:String = "ping_04.mp3";
		static private const ENGINE_HUM:String = "engine_high_01_L.mp3";
		static private const HEART_BEAT:String = "heart_beat_02_L.mp3";
	} // class

} // package