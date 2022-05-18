package game.scenes.virusHunter.joesCondo {

	import com.greensock.TweenLite;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.collider.SceneCollider;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Sneeze;
	import game.data.comm.PopResponse;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PhotoGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.condoInterior.systems.SimpleUpdateSystem;
	import game.scenes.virusHunter.joesCondo.classes.EatingCutScene;
	import game.scenes.virusHunter.joesCondo.classes.FlameEmitter;
	import game.scenes.virusHunter.joesCondo.creators.ClipCreator;
	import game.scenes.virusHunter.joesCondo.creators.RollingObjectCreator;
	import game.scenes.virusHunter.joesCondo.systems.RollingObjectSystem;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.scenes.virusHunter.stomach.Stomach;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.ActionCommand;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.EventAction;
	import game.systems.actionChain.actions.FollowAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetVisibleAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.StopFollowAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitCallbackAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ZoneHitSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.renderers.DisplayObjectRenderer;
	
	public class JoesCondo extends PlatformerGameScene {

		static private const CHINESE_ITEM:String = "vh_chinese";

		private var updateObj:Object;

		public var pVelocity:Point;

		public var clipCreator:ClipCreator;
		public var rollerCreator:RollingObjectCreator;

		public var joe:Entity;
		public var scientist:Entity;
		public var drlange:Entity;

		public var virusEvents:VirusHunterEvents;

		// front door will animate and all that stuff.
		public var frontDoor:Entity;

		public var actionChain:ActionChain;					// Chains together a sequence of actions.

		public function JoesCondo() {

			super();

		} //
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void {

			super.groupPrefix = "scenes/virusHunter/joesCondo/";
			super.init(container);

		} //

		// initiate asset load of scene specific assets.
		override public function load():void {
			super.load();
		} //
		
		// all assets ready
		override public function loaded():void
		{
			this.addSystem( new ZoneHitSystem(), SystemPriorities.update );
			this.addSystem( new RollingObjectSystem(), SystemPriorities.update );

			this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );

			rollerCreator = new RollingObjectCreator( this._hitContainer, this );

			initFrontDoor();
			initChars();
			initPapers();
			initFlames();

			virusEvents = super.events as VirusHunterEvents;
			if ( !super.shellApi.checkEvent( virusEvents.COMPLETED_TUTORIAL ) ) {

				this._hitContainer.removeChild( this._hitContainer["scientistMask"] );
				this.removeEntity( drlange );
				this.removeEntity( scientist );
				this.removeEntity( joe );

			} else if ( super.shellApi.checkEvent( virusEvents.LUNG_BOSS_DEFEATED ) == false ) {

				// making characters dynamically seems very, very, unstable.
				//loadScientist();
				doScientistScene();			// do the scientist cutscene.

			} else if ( !shellApi.checkHasItem( "medalVirusHunter" ) ) {

				this._hitContainer.removeChild( this._hitContainer["scientistMask"] );
				doEndScene();

			} else {

				this._hitContainer.removeChild( this._hitContainer["scientistMask"] );
				this.removeEntity( drlange );
				this.removeEntity( scientist );

			} //

			super.loaded();

		} //

		private function doEndScene():void {

			//shellApi.completedIsland();
			
			// place the scientist and lange in the correct places?
			var joeSpatial:Spatial = joe.get( Spatial );
			var joeStand:MovieClip = _hitContainer[ "joeEndStand" ];
			joeSpatial.x = joeStand.x;

			var targ:MotionTarget = joe.get( MotionTarget );
			if ( targ ) {
				targ.targetX = joeSpatial.x;
			} //


			CharUtils.setDirection( joe, true );

			SimpleUtils.showChar( scientist, true );
			SimpleUtils.showChar( drlange, true );
			SimpleUtils.hideChar( player );

			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( drlange );
			charGroup.addFSM( joe );
			charGroup.addFSM( scientist );

			SceneUtil.setCameraTarget( this, joe, false );

			var endChain:ActionChain = new ActionChain( this );
			endChain.autoUnlock = true;
			endChain.lockInput = true;

			endChain.addAction( new AnimationAction( joe, Sneeze, "fire" ) );

			var a:ActionCommand = new TalkAction( joe, "sneeze" );
			a.noWait = true;
			endChain.addAction( a );

			a = new CallFunctionAction( expelPlayer );
			a.endDelay = 2;
			endChain.addAction( a );

			endChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, player, false ) ) );
			endChain.addAction( new FollowAction( scientist, drlange ) );
			endChain.addAction( new MoveAction( drlange, new Point( joeSpatial.x - 150, joeSpatial.y ) ) );
			endChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, joe, false) ) );
			endChain.addAction( new TalkAction( drlange, "endConvo1" ) );
			endChain.addAction( new StopFollowAction( scientist, false, true ) );
			endChain.addAction( new MoveAction( scientist, new Point( joeSpatial.x - 50, joeSpatial.y) ) );
			endChain.addAction( new AnimationAction( scientist, PointItem, "pointing" ) );
			endChain.addAction( new TalkAction( joe, "endConvo2" ) );
			endChain.addAction( new TalkAction( drlange, "endConvo3" ) );
			endChain.addAction( new TalkAction( joe, "endConvo4" ) );
			endChain.addAction( new TalkAction( drlange, "endConvo5" ) );

			var celebrate:AnimationAction = new AnimationAction( joe, Celebrate, "trigger" );
			celebrate.startDelay = 1;

			endChain.addAction( celebrate );
			endChain.addAction( new TalkAction( joe, "endConvo6" ) );
			endChain.addAction( new WaitCallbackAction( growPlayer ) );

			endChain.addAction( new TalkAction( player, "endConvo7" ) );
			endChain.addAction( new TalkAction( drlange, "endConvo8" ) );
			endChain.addAction( new GetItemAction( "medalVirusHunter" ) );

			endChain.execute( endChainDone );

			var dialog:Dialog = joe.get( Dialog );
			if ( dialog ) {
				dialog.faceSpeaker = false;
			} //

		} //

		private function endChainDone( ac:ActionChain ):void {

			CharUtils.lockControls( player, false, false );
			SceneUtil.setCameraTarget( this, player );

			var cmc:CharacterMotionControl = player.get( CharacterMotionControl );
			cmc.allowAutoTarget = true;

			// NEED TO CORRECT PLAYER TARGETING TOO.

			/*var t:MotionTarget = scientist.get( MotionTarget );
			if ( t ) {
				var s:Spatial = scientist.get( Spatial );
				t.targetX = s.x;
			}*/
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			var islandEndingPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer);
			islandEndingPopup.hasBonusQuestButton = true;
			this.addChildGroup(islandEndingPopup);
		} //

		/**
		 * The callback function, when called, will trigger the action chain to continue.
		 */
		private function growPlayer( callback:Function ):void {

			// To avoid hardcoding the default scale, just take it from joe.
			var joeSpatial:Spatial = joe.get( Spatial );

			TweenLite.to( player.get(Spatial), 1, { scaleX:joeSpatial.scaleX, scaleY:joeSpatial.scaleY, onComplete:callback, onUpdate:fixScale } );

		} //

		private function fixScale():void {

			var pSpatial:Spatial = player.get( Spatial );
			CharUtils.setScale( player, pSpatial.scaleX );

		} //

		/**
		 * Shoot the stupid player out of joe's stupid nose. Calling {callback} will make
		 * the action list continue.
		 */
		private function expelPlayer():void {

			var pSpatial:Spatial = player.get( Spatial );

			CharUtils.setScale( player, 0.08 );

			//var mc:MotionControl = player.get(MotionControl );
			//mc.forceTarget = false;
			//mc.inputStateChange = false;
			//mc.moveToTarget = false;
			//mc.inputStateDown = false;

			CharUtils.setState( super.player, CharacterState.FALL );

			var cmc:CharacterMotionControl = player.get( CharacterMotionControl );
			cmc.allowAutoTarget = false;

			//var targ:MotionTarget = player.get( MotionTarget );
			//targ.updateTarget = false;
			//targ.targetFinalReached = false;
			//targ.targetReached = false;
			//targ.checkReached = false;

			var jClip:DisplayObjectContainer = ( joe.get( Display ) as Display ).displayObject;

			// put the player the approx location of joe's nose.
			pSpatial.x = jClip.x;
			pSpatial.y = jClip.y - 0.8*jClip.height;

			var pMotion:Motion = player.get( Motion );
			pMotion.friction.x = 0;
			pMotion.velocity.x = 300;
			pMotion.velocity.y = -90;

			pVelocity = pMotion.velocity;

			SimpleUtils.showChar( player, true );

			/*var updater:SimpleUpdater = new SimpleUpdater( testChanges );
			player.add( updater );

			updateObj = new Object();
			updateObj.updateTarget = targ.updateTarget;
			updateObj.targetFinalReached = targ.targetFinalReached;
			updateObj.targetReached = targ.targetReached;
			updateObj.checkReached = targ.checkReached;

			updateObj.forceTarget = mc.forceTarget;
			updateObj.inputStateChange = mc.inputStateChange;
			updateObj.moveToTarger = mc.moveToTarget;
			updateObj.inputStateDown = mc.inputStateDown;*/

		} //

		private function doScientistScene():void {
			
			this.shellApi.triggerEvent("start_condo_music");
			
			SimpleUtils.hideChar( player );
			SimpleUtils.hideChar( drlange );

			// Hide the player; take away control, etc.
			( this.getSystem( CameraSystem ) as CameraSystem ).target = scientist.get( Spatial );

			SkinUtils.setSkinPart( scientist, SkinUtils.ITEM, CHINESE_ITEM, false );
			var scienceDisplay:Display = scientist.get( Display );
			scienceDisplay.visible = false;

			// set the mask for the scientist.
			var clip:MovieClip = scienceDisplay.displayObject as MovieClip;
			clip.mask = this._hitContainer["scientistMask"];

			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( joe );

			charGroup.addFSM( scientist );
			// to allow scientist to walk out of scene extend his motion bounds and remove SceneCollider
			MotionBounds(scientist.get( MotionBounds )).box.left -= 200;
			scientist.remove( SceneCollider );
			

			actionChain = new ActionChain( this );
			actionChain.lockInput = true;

			// This will trigger the knocking sound.
			//var action:EventAction = new EventAction( super.shellApi, "knockOnDoor", "knockDone" );

			actionChain.addAction( new EventAction( super.shellApi, "knockOnDoor" ) );
			actionChain.addAction( new TalkAction( scientist, "sayDelivery" ) );

			// pan the camera WHILE joe is moving.
			var action:ActionCommand = new PanAction( joe );
			//action.noWait = true;

			actionChain.addAction( action );
			actionChain.addAction( new MoveAction( joe, _hitContainer["joeStand1"] ) );
			actionChain.addAction( new TalkAction( joe, "sayDidntOrder" ) );

			actionChain.addAction( new TalkAction( scientist, "sayItsFree" ) );	
			actionChain.addAction( new TalkAction( joe, "sayThatsMyOrder" ) );
			actionChain.addAction( new TimelineAction( frontDoor, "open", "openComplete" ) );

			// Now we make the scientist visible.
			actionChain.addAction( new SetVisibleAction( scienceDisplay, true ) );
			actionChain.addAction( new MoveAction( scientist, _hitContainer["scientistStand1"] ) );

			// Need to sort of... make the scientist point first, then joe, to pass off the item.
			action = new AnimationAction( scientist, PointItem );
			action.noWait = true;
			actionChain.addAction( action );

			action = new AnimationAction( joe, PointItem, "pointing" );
			action.startDelay = 0.1;
			actionChain.addAction( action );

			// switch item here.
			actionChain.addAction( new SetSkinAction( joe, SkinUtils.ITEM, CHINESE_ITEM, false, true ) );
			actionChain.addAction( new SetSkinAction( scientist, SkinUtils.ITEM, SkinPart.EMPTY, false, false ) );

			// scientist walks off screen, joe walks to food.

			// Note: scientist doesnt appear to actually make it through this stand location, because its offscreen.
			action = new MoveAction( scientist, _hitContainer["scientistStand2"] );
			action.noWait = true;
			actionChain.addAction( action );

			// annoying. need to delay the close door to give time for the scientist to get out.
			action = new TimelineAction( frontDoor, "close", "closeComplete" );
			action.startDelay = 1;
			actionChain.addAction( action );
			
			// want to hide scientist once they have reached the door
			//actionChain.addAction( new RemoveComponentAction( scientist, Display ) );
			
			actionChain.addAction( new MoveAction( joe, _hitContainer["joeStand2"] ) );
			//actionChain.addAction( new AnimationAction( joe, Eat, "end" ) );

			actionChain.execute( scientistDone );

		} //

		private function scientistDone( chain:ActionChain ):void
		{
			var popup:EatingCutScene = new EatingCutScene( "eatingPopup.swf", this.groupPrefix, this.overlayContainer, this.popupReachedEnd );
			popup.id = "eatingPopup";
			
			// Display the eating popup.
			super.addChildGroup( popup );

			shellApi.triggerEvent("being_swallowed");
		}

		private function popupReachedEnd():void
		{
			shellApi.triggerEvent( virusEvents.ENTERED_JOE, true );
			
			// when popup is ready to close we may need to take a photo
			// we have to close the popup first though because it is hiding the hud
			// TODO :: The photo animation shouldn;t be tied to the hud, but be independent, so it can be shown anywhere - bard
			var photoGroup:PhotoGroup = getGroupById(PhotoGroup.GROUP_ID) as PhotoGroup;
			if (photoGroup && photoGroup.shouldTakePhoto("12650") ) 
			{
				var popup:EatingCutScene = getGroupById('eatingPopup') as EatingCutScene;
				popup.removed.addOnce(takePhoto);
				popup.close();
			} 
			else 
			{
				loadStomach();
			}
		}

		private function takePhoto(...args):void
		{
			shellApi.takePhoto("12650", loadStomach );
		}

		private function loadStomach():void
		{
			shellApi.loadScene( Stomach );
		}

		// The scene has some rolling/hittable papers.
		public function initPapers():void {

			var i:int = 0;
			var clip:Sprite = this._hitContainer["paper"+i];

			while ( clip != null ) {

				rollerCreator.createRoller( clip );

				i++;
				clip = this._hitContainer["paper"+i];

			} // end-while.

		} //

		public function initFlames():void {

			var blur:Array = [ new BlurFilter( 2, 2, 3 ) ];

			// FIRST FLAME
			var emitter:FlameEmitter = new FlameEmitter();

			var clip:MovieClip = this._hitContainer["flame0"];
			var flame:Entity = EmitterCreator.create( this, super._hitContainer, emitter, clip.x, clip.y );

			this._hitContainer.removeChild( clip );			// don't need it anymore.

			var display:DisplayObjectRenderer = ( flame.get( Display ) as Display ).displayObject as DisplayObjectRenderer;
			display.filters = blur;
			emitter.init();

			// SECOND FLAME
			emitter = new FlameEmitter();

			clip = this._hitContainer["flame1"];
			flame = EmitterCreator.create( this, super._hitContainer, emitter, clip.x, clip.y );

			this._hitContainer.removeChild( clip );			// don't need it anymore.
			
			display = ( flame.get( Display ) as Display ).displayObject as DisplayObjectRenderer;
			display.filters = blur;

			emitter.init();

			// Place player above the flames.
			var mc:DisplayObjectContainer = ( player.get(Display) as Display ).displayObject;
			this._hitContainer.swapChildren( display, mc );

		} //

		private function initFrontDoor():void {

			frontDoor = TimelineUtils.convertClip( this._hitContainer["frontDoor"], this );

			var tl:Timeline = frontDoor.get( Timeline );
			tl.playing = false;

		} //

		private function hideScientist():void {

			SimpleUtils.hideChar( scientist );

			this._hitContainer["scientistMask"].visible = false;

		} //

		private function initChars():void {

			joe = this.getEntityById( "joe" );
			scientist = this.getEntityById( "scientist" );
			drlange = this.getEntityById( "drlange" );

		} //

		/*private function loadScientist():void {
			
			var condoExit:Spatial = this.getEntityById( "condoExit" ).get( Spatial );

			var look:LookData = new LookData();
			look.applyLook( "male", 0xfde7b6, 0xf08b2c, "open", "69", "beardshort2", "7", "10", "dadchar1", "wwdeputy", "1", "paper", "labcoat", "1" );

			var charGroup:CharacterGroup = super.getGroupById( "characterGroup" ) as CharacterGroup;
			scientist = charGroup.createNpc( "scientist", look, condoExit.x, condoExit.y, "right" );

		} // loadScientist()*/

	} // class

} // package