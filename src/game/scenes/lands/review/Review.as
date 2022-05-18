package game.scenes.lands.review {

	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.system.Security;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.scene.template.CameraGroup;
	import game.scene.template.GameScene;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.systems.InputManagerSystem;
	import game.scenes.lands.shared.world.LandRealmData;
	import game.scenes.lands.shared.world.PendingWorldSource;
	import game.systems.SystemPriorities;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;

	public class Review extends Scene {

		/**
		 * TEMP used for logWWW in other classes without tons of references.
		 */
		static public var Shell:ShellApi;

		private var master:Entity;
		private var fade:ScreenEffects;

		private var reviewUI:ReviewUI;

		/**
		 * this paints the current realm and then copies it over to the realm display.
		 */
		private var realmPainter:RealmPainter;

		/**
		 * this object encapsulates a bitmap with special functions for displaying the realm scenes side by side in a single bitmap.
		 * the scenes are painted into a scene bitmap by the realm painter
		 * and then scaled and copied to their correct positions in the realm display.
		 */
		private var realmDisplay:RealmDisplay;

		/**
		 * sort of vague right now. takes the place of 'LandGroup' from realms, and handles loading tile files, biome files,
		 * and all the assets that realms needs to display. some world management and communication is also mixed up in there.
		 */
		private var assetGroup:ReviewAssetGroup;
		//private var worldSource:PendingWorldSource;

		private var inputMgr:InputManager;

		private var realmIterator:RealmIterator;

		public function Review() {

			super();

		} //

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			super.groupPrefix = "scenes/lands/review/";

			super.init( container );
			this.load();

			this.shellApi.defaultCursor = ToolTipType.TARGET;
			Review.Shell = this.shellApi;

		} //

		// initiate asset load of scene specific assets.
		override public function load():void {

			this.initInputEntity();

			super.shellApi.fileLoadComplete.addOnce( this.loadSceneAssets );
			super.loadFiles([GameScene.SCENE_FILE_NAME]);

		} //

		/**
		 * load whatever is needed from scene.xml i guess.
		 * need to do this to have access to the SceneData object.
		 */
		protected function loadSceneAssets():void {

			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);

			super.sceneData = parser.parse( sceneXml );			
			super.shellApi.fileLoadComplete.addOnce( this.loadUI );
			super.loadFiles( super.sceneData.assets );

		} //

		private function loadUI():void {

			this.reviewUI = new ReviewUI( this, this.inputMgr );
			this.reviewUI.load( this.onUILoaded );

		} //

		private function onUILoaded():void {

			this.reviewUI.reviewPane.onApprove = this.approveCurrentRealm;
			this.reviewUI.reviewPane.onNext = this.advanceRealm;
			this.reviewUI.reviewPane.onReject = this.rejectCurrentRealm;
			this.reviewUI.reviewPane.onRefreshPending = this.loadPendingWorlds;

			this.reviewUI.onLocalLoad = this.loadLocalWorld;

			this.reviewUI.reviewPane.onPopularize = this.popularizeRealm;

			// PREPARING THE ASSET GROUP THAT CONTROLS THE REALMS ASSETS:

			this.assetGroup = new ReviewAssetGroup( this );

			//this.assetGroup.onBiomeChanged.add( this.onBiomeChanged );
			this.assetGroup.onGalaxyLoaded.add( this.onGalaxyLoaded );

			this.addChildGroup( this.assetGroup );

			this.assetGroup.ready.add( this.assetGroupReady );
			this.assetGroup.init();

			Security.loadPolicyFile( "https://s3.amazonaws.com/poptropica-realms-thumbnails/crossdomain.xml" );

		} //

		private function assetGroupReady( group:Group ):void {

			this.loaded();

		} //

		// all assets ready
		override public function loaded():void {

			super.loaded();

			this.addSystem( new InputManagerSystem(), SystemPriorities.preUpdate );

			// iterates through the realms of the current galaxy.
			this.realmIterator = new RealmIterator( this.assetGroup.worldMgr.galaxy );
			// copies complete realm bitmaps into a single bitmap containing ALL realms.
			this.realmDisplay = new RealmDisplay( this.inputMgr, this.groupContainer );
			// paints the current realm into a bitmap and then copies it into the realm display.
			this.realmPainter = new RealmPainter( this.reviewUI, this.assetGroup.worldMgr, this.realmDisplay,
				this.assetGroup.assetLoader, this.assetGroup.gameData );

			//this.createBackground();
			//this.addCamera();

			// by default, load worlds pending from server.
			this.assetGroup.loadPendingWorlds();

		} //

		protected function createBackground():void {

			var backgroundClip:Sprite = new Sprite();
			var g:Graphics = backgroundClip.graphics;
			g.beginFill( 0xAAAAAA, 1 );
			g.drawRect( 0, 0, 1000, 1000 );
			g.endFill();

			this.groupContainer.addChild( backgroundClip );

			var e:Entity = new Entity()
				.add( new Id( "background" ), Id )
				.add( new Spatial(), Spatial )
				.add( new Display( backgroundClip ), Display );

			this.addEntity( e );

		} //

		protected function addCamera():void {

			var cameraGroup:CameraGroup = new CameraGroup();
			cameraGroup.allowLayerGrid = false;

			var offsetCameraPosition:Boolean = true;

			if ( super.sceneData.cameraLimits == null ) {
				offsetCameraPosition = false;
				super.sceneData.cameraLimits = new Rectangle( 0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			}

			// This method of cameraGroup does all setup needed to add a camera to this scene.  After calling this method you just need to assign cameraGroup.target to the spatial component of the Entity you want to follow.
			cameraGroup.setupScene( this, 1, offsetCameraPosition );

		}

		public function loadLocalWorld():void {

			this.assetGroup.loadLocalWorld();

		} //

		public function loadPendingWorlds():void {

			this.assetGroup.reloadPendingWorlds();

		} //

		public function onGalaxyLoaded( success:Boolean ):void {

			if ( success ) {

				if ( this.realmIterator.getRealmCount() == 0 ) {

					this.reviewUI.showMessage( "NO PENDING REALMS." );
					this.realmDisplay.clear();
					this.unlockScreen();
					// still need to lock the BUTTONS in this case.
					this.reviewUI.lockInput();

				} else {

					this.realmIterator.reset();
					this.displayCurrentRealm();

				}

				this.reviewUI.setTotalPending( (this.assetGroup.worldMgr.worldSource as PendingWorldSource).totalPendingRealms );

			} else {

				this.reviewUI.showMessage( "Error: could not fetch pending realms." );
				this.realmDisplay.clear();
				this.unlockScreen();
				this.reviewUI.lockInput();


			} //

		} //

		/**
		 * last realm in the iterator reached.
		 */
		public function onIteratorEnd():void {

			var source:PendingWorldSource = this.assetGroup.worldMgr.worldSource as PendingWorldSource;
			if ( source == null ) {

				this.shellApi.logWWW( "major error: no pending world source." );
				// local world or something.. just loop around.
				this.realmIterator.reset();
				this.displayCurrentRealm();

			} else {

				// load the next page of realms.
				this.shellApi.logWWW( "No cached pending realms. Attempting to load more." );
				source.advancePage( this.onGalaxyLoaded );

			} //

		} //

		public function displayCurrentRealm():void {

			var curRealm:LandRealmData = this.realmIterator.currentRealm;
			if ( curRealm == null ) {
				this.reviewUI.showMessage( "Error: current realm is null" );
				this.reviewUI.lockInput();
				return;
			} //

			this.realmDisplay.clear();
			this.reviewUI.displayRealm( curRealm );

			if ( !curRealm.hasSavedScenes() ) {
				this.autoRejectRealm();
				return;
			} //

			// need to actually get to the current realm here; then make sure the right biome is loaded.
			// the scenes can't actually be displayed until the correct biome has beed loaded for the current realm.

			this.lockScreen();

			if ( this.assetGroup.prepareCurrentRealm() ) {

				this.realmPainter.displayAllScenes( curRealm, this.onRealmPainted );

			} else {

				this.reviewUI.showMessage( "Loading realm biome..." );
				// display the scenes after the biome data loads?
				this.assetGroup.onBiomeChanged.addOnce( Command.create( this.realmPainter.displayAllScenes, curRealm, this.onRealmPainted ) );

			} //

		} //

		private function onRealmPainted():void {

			this.reviewUI.showMessage( "All scenes painted." );
			this.unlockScreen();

		} //

		private function lockScreen():void {

			this.reviewUI.lockInput();
			SceneUtil.lockInput( this, true );

		} //

		private function unlockScreen():void {

			this.reviewUI.unlockInput();
			SceneUtil.lockInput( this, false );

		} //

		/**
		 * not sure where all these functions should go yet:
		 */
		public function rejectCurrentRealm():void {

			this.lockScreen();

			var worldSource:PendingWorldSource = this.assetGroup.worldMgr.worldSource as PendingWorldSource;
			if ( worldSource == null ) {
				return;
			}
			worldSource.rejectRealm( this.realmIterator.currentRealm.id, this.onRealmRejected );

			this.reviewUI.showMessage( "attempting to reject..." );


		} //

		public function autoRejectRealm():void {
			
			this.lockScreen();
			
			var worldSource:PendingWorldSource = this.assetGroup.worldMgr.worldSource as PendingWorldSource;
			if ( worldSource == null ) {
				return;
			}
			worldSource.rejectRealm( this.realmIterator.currentRealm.id, this.onRealmAutoRejected );

			this.reviewUI.showMessage( "realm has no scenes. rejecting and advancing..." );
			
		} //

		public function approveCurrentRealm():void {

			this.lockScreen();

			var worldSource:PendingWorldSource = this.assetGroup.worldMgr.worldSource as PendingWorldSource;
			if ( worldSource == null ) {
				return;
			}
			worldSource.approveRealm( this.realmIterator.currentRealm.id, this.onRealmApproved );

			this.reviewUI.showMessage( "attempting to approve..." );
			//this.advanceRealm();

		} //

		private function onRealmApproved( success:Boolean ):void {

			if ( !success ) {

				this.reviewUI.showMessage( "ERROR: realm not approved." );
				this.unlockScreen();

			} else {

				this.reviewUI.showMessage( "Realm approved. fetching next realm." );
				this.advanceRealm();

			}

			this.reviewUI.setTotalPending( (this.assetGroup.worldMgr.worldSource as PendingWorldSource).totalPendingRealms );

		} //

		private function onRealmAutoRejected( success:Boolean ):void {

			if ( !success ) {
				
				this.reviewUI.showMessage( "ERROR: realm not rejected." );
				
			} else {
				
				this.reviewUI.showMessage( "Realm rejected. fetching next realm." );		
			}

			this.reviewUI.setTotalPending( (this.assetGroup.worldMgr.worldSource as PendingWorldSource).totalPendingRealms );
			this.advanceRealm();

		} //

		private function onRealmRejected( success:Boolean ):void {
			
			if ( !success ) {

				this.reviewUI.showMessage( "ERROR: realm not rejected." );
				this.unlockScreen();

			} else {
				
				this.reviewUI.showMessage( "Realm rejected. fetching next realm." );
				this.advanceRealm();		
			}

			this.reviewUI.setTotalPending( (this.assetGroup.worldMgr.worldSource as PendingWorldSource).totalPendingRealms );

		} //
		
		/*private function realmStatusChanged( success:Boolean ):void {

			if ( !success ) {
				this.shellApi.logWWW( "ERROR: realm status was not changed." );
			} //

			this.advanceRealm();

		} //*/

		public function advanceRealm():void {

			//this.shellApi.logWWW( "DISPLAYING NEXT REALM" );

			if ( this.realmIterator.advanceRealm() ) {

				this.displayCurrentRealm();

			} else {

				// Noo more realms; need to load the next page of realms.
				this.shellApi.logWWW( "No more realms. Fetching next page..." );
				this.onIteratorEnd();

			} //

		} //

		public function popularizeRealm():void {

			var worldSource:PendingWorldSource = this.assetGroup.worldMgr.worldSource as PendingWorldSource;
			if ( worldSource == null ) {
				return;
			}
			worldSource.markPopular( this.realmIterator.currentRealm.id, this.onRealmPopularized );
			
			this.reviewUI.showMessage( "attempting to set popularity..." );

			// approve at the same time.
			this.approveCurrentRealm();

		} //

		public function onRealmPopularized( success:Boolean ):void {

			if ( success ) {
				this.reviewUI.showMessage( "realm popularity set." );
			} else {
				this.reviewUI.showMessage( "error: realm popularity could not be set." );
			} //

		} //

		/**
		 * called when the currently loaded biome changes.
		 */
		//public function onBiomeChanged():void {
		//} //

		private function initInputEntity():void {

			this.inputMgr = new InputManager();

			var e:Entity = new Entity()
				.add( this.inputMgr, InputManager );

			this.addEntity( e );

		} //

		override public function destroy():void {

			this.realmDisplay.destroy();
			super.destroy();

		} //

	} // class
	
} // package