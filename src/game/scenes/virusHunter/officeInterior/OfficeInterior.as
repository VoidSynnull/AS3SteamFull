package game.scenes.virusHunter.officeInterior {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Wall;
	import game.components.motion.Edge;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.KeyboardTyping;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.TakePhoto;
	import game.data.animation.entity.character.Think;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PhotoGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.condoInterior.classes.UpdateManager;
	import game.scenes.virusHunter.joesCondo.components.ActionClick;
	import game.scenes.virusHunter.joesCondo.creators.ClipCreator;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.scenes.virusHunter.officeInterior.classes.ComputerScreen;
	import game.scenes.virusHunter.officeInterior.classes.SecurityGate;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.ActionCommand;
	import game.systems.actionChain.ActionList;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.FollowAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.StopFollowAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitCallbackAction;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;

	public class OfficeInterior extends PlatformerGameScene {

		private var clipCreator:ClipCreator;

		private var computers:Vector.<ComputerScreen>;			// office computer screens.

		//static private var npcAnimations:Array = [ Think, Type

		private var npcs:Vector.<Entity>;			// Normal npcs.

		private var joe:Entity;						// it's joe.

		// An npc (choosing female so its not confused with joe) that enters at the same time as the player.
		// The player tries to follow but gets stopped at the gate.
		private var npcWalker:Entity;

		// This guy isn't needed much so he'll be created dynamically.
		private var falafelGuy:Entity;

		// Zone where the player will get called out by the guard.
		private var gateZone:Entity;
		private var gateWall:Entity;

		private var actionChain:ActionChain;

		private var virusEvents:VirusHunterEvents;

		private var securityGate:SecurityGate;
		private var updateMgr:UpdateManager;

		// The guard is no longer a full npc. Just a clip that indicates where the gate dialog should come from.
		private var guard:Entity;

		// A repeatable action chain for blocking the gate.
		private var blockGateChain:ActionChain;

		private var leftGateStand:MovieClip;
		private var rightGateStand:MovieClip;

		private var temp:Number;
		private var updater:UpdateManager;

		public function OfficeInterior() {			// this is a constructor.

			super();								// this calls a super constructor.

		}											// this is a closing brace.
													// this line is just white space.
		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			super.groupPrefix = "scenes/virusHunter/officeInterior/";

			super.init(container);

		} //
		
		// initiate asset load of scene specific assets.
		override public function load():void {

			super.load();

		} //
		
		// all assets ready
		override public function loaded():void {

			// this doesn't appear to get added automatically.
			//this.addSystem( new ZoneHitSystem(), SystemPriorities.update );
			virusEvents = super.events as VirusHunterEvents;

			initChars();

			updateMgr = new UpdateManager( this );

			clipCreator = new ClipCreator( this );

			initGate();
			initComputerScreens();
			initCamera();			// player camera item that he uses to take pictures.

			initVendingMachine();

			if ( super.shellApi.checkEvent( virusEvents.DELIVERED_FALAFEL ) ) {

				putWalkerAtDesk();
				SimpleUtils.hideChar( falafelGuy );
				disableGateZone();
				securityGate.doOpen();

			} else if ( super.shellApi.checkEvent( virusEvents.DELIVERING_FALAFEL ) ) {

				putWalkerAtDesk();
				doFalafelScene();

			} else {

				//putWalkerAtDesk();
				//doFalafelScene();

				SimpleUtils.hideChar( falafelGuy );
				doNpcWalker();

			} //

			super.loaded();

		} //

		private function animDone( e:Entity ):void {
			//trace( "DONE" );
		} //

		// Npc enters the office and the player attempts to follow.
		private function doNpcWalker():void {

			SimpleUtils.disableSleep( npcWalker );
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( npcWalker );

			var charMotionCtrl:CharacterMotionControl = npcWalker.get( CharacterMotionControl );
			if ( charMotionCtrl != null ) {
				charMotionCtrl.maxVelocityX = 400;
			} //

			disableGateZone();

			CharUtils.setDirection( npcWalker, true );

			actionChain = new ActionChain( this );
			actionChain.lockInput = true;

			var action:ActionCommand = new FollowAction( player, npcWalker );
			action.noWait = true;

			actionChain.addAction( action );
			actionChain.addAction( new MoveAction( npcWalker, leftGateStand ) );

			//action = new WaitCallbackAction( securityGate.doOpen );
			//action.noWait = true;
			actionChain.addAction( new WaitCallbackAction( securityGate.doOpen ) );

			actionChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, npcWalker, false) ) );
			actionChain.addAction( new TalkAction( npcWalker, "noPiggybacking" ) );
			actionChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, npcWalker, true) ) );

			actionChain.addAction( new StopFollowAction( player, true, true ) );
			// Npc goes to the far side of the gate, then moves offscreen.
			actionChain.addAction( new MoveAction( npcWalker, rightGateStand ) );

			// Move action ends immediately to make gate come back down.
			action = new MoveAction( npcWalker, _hitContainer["falafelFinal"] );
			action.noWait = true;
			actionChain.addAction( action  );

			actionChain.addAction( new WaitCallbackAction( securityGate.doClose ) );

			actionChain.execute( npcEntered );

		} //

		private function doFalafelScene():void {

			SimpleUtils.disableSleep( falafelGuy );

			disableGateZone();

			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( falafelGuy );
			( falafelGuy.get( Dialog ) as Dialog ).faceSpeaker = false;
			
			CharUtils.followEntity( player, falafelGuy, (new Point(80, 100)) );

			// for some reason, the falafel guy won't turn by default...
			CharUtils.setDirection( falafelGuy, true );

			SceneUtil.setCameraTarget( this, falafelGuy );

			actionChain = new ActionChain( this );
			actionChain.lockInput = true;

			// FalafelGuy goes up to the guard door, with the player following behind.
			actionChain.addAction( new MoveAction( falafelGuy, leftGateStand, null, rightGateStand.x  ) );
			actionChain.addAction( new TalkAction( falafelGuy, "delivery" ) );
			actionChain.addAction( new AnimationAction( falafelGuy, Salute ) );
			actionChain.addAction( new TalkAction( guard, "come_in" ) );
			actionChain.addAction( new WaitCallbackAction( securityGate.doOpen ) );
			actionChain.addAction( new PanAction( player ) );

			// After the guard gives the all clear, the falafelGuy runs offscreen and disappears.
			var actionList:ActionList = new ActionList();
			actionList.addAction( new MoveAction( falafelGuy, _hitContainer["falafelFinal"] ) );
			actionList.addAction( new CallFunctionAction( Command.create(SimpleUtils.hideChar, falafelGuy) ) );
			actionList.noWait = true;
			actionChain.addAction( actionList );

			actionChain.addAction( new StopFollowAction( player, true, true ) );

			actionChain.execute( falafelDone );

		} //

		private function falafelDone( chain:ActionChain ):void {

			shellApi.completeEvent( virusEvents.DELIVERED_FALAFEL );

			//trace( "FALAFEL CHAIN DONE" );
			//trace( "post1: " + Input( this.shellApi.inputEntity.get( Input ) ).lockInput );
			//CharUtils.lockControls( player, false );

		} //

		// npc entered the office and left the player behind.
		private function npcEntered( chain:ActionChain ):void {

			// don't need to put walker at desk because player can't cross - duh.
			//putWalkerAtDesk();

			actionChain.destroy();
			actionChain = null;

			enableGateZone();

		} //

		/*private function actionDone( action:ActionCommand ):void {
			trace( "ACTION DONE: " );
		} //*/

		private function initCamera():void {

			super.shellApi.eventTriggered.add( onEventTriggered );

		} //

		private function onEventTriggered( event:String, save:Boolean, init:Boolean=false, removeEvent:String=null ):void {

			if ( event == "TakePhotoEvent" ) {

				if ( shellApi.checkHasItem( "photo" ) ) {

					// player already has the photo.
					SimpleUtils.manualSay( player, "havePicture" );

				} else {

					tryTakePhoto();

				} //

			} // switch-event.

		} // onEventTriggered()

		private function initVendingMachine():void {

			var vendingMachine:MovieClip = this._hitContainer[ "vendingMachine" ];

			var entity:Entity = clipCreator.createActionClick( vendingMachine, null, resetVendingMachine );

			var play:TimelineAction = new TimelineAction( entity, "on", "end" );

			var click:ActionClick = entity.get( ActionClick ) as ActionClick;
			click.action = play;

			TimelineUtils.convertClip( vendingMachine, this, entity );
			var tl:Timeline = entity.get( Timeline ) as Timeline;
			tl.gotoAndStop( 1 );

		} //

		private function resetVendingMachine( vendor:Entity ):void {

			var tl:Timeline = vendor.get( Timeline ) as Timeline;
			tl.gotoAndStop( 1 );

		} //

		// block the player from entering the office until he follows the pizza guy through.
		// which frankly is going to be a big hassle.
		private function initGate():void {

			//var zoneClip:MovieClip = this._hitContainer["gateZone"];

			leftGateStand = this._hitContainer["leftGateStand"];
			rightGateStand = this._hitContainer["rightGateStand"];

			// Move the guard door to the front of the child clips.
			var gate:MovieClip = this._hitContainer["securityGate"];
			this._hitContainer.setChildIndex( gate, this._hitContainer.numChildren-1 );

			gateZone = clipCreator.createZoneEntity( this._hitContainer["gateZone"], this.blockGateEnter );
			securityGate = new SecurityGate( gate, updateMgr, this );

			gateWall = this.getEntityById( "wallGate" );

		} //

		private function disableGateZone():void {

			gateWall.remove( Wall );

			var sleep:Sleep = gateZone.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = true;

			//var zone:Zone = gateZone.get( Zone );
			//zone.entered.remove( enterGateZone );

		} //

		private function enableGateZone():void {

			gateWall.add( new Wall() );

			var sleep:Sleep = gateZone.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false;
			
		} //

		private function blockGateEnter( hitId:String, entityId:String ):void {

			// Make sure its the player that entered the stupid guard zone.
			if ( entityId != "player" ) {
				return;
			}

			if ( blockGateChain != null ) {

				blockGateChain.execute();

			} else {

				// clip in scene where player walks back to.
				var leftStand:MovieClip = this._hitContainer["leftGateStand"];

				blockGateChain = new ActionChain( this );
				blockGateChain.lockInput = true;
				//blockGateChain.onComplete = blockGateComplete;

				// This is a bit obnoxious. the zone "enter" will give multiple hits when you're near the edge.
				var pt:Point = new Point( leftStand.x - 60, leftStand.y );
				blockGateChain.addAction( new MoveAction( player, pt ) );
				blockGateChain.addAction( new TalkAction( player, "noOpen" ) );
				blockGateChain.addAction( new CallFunctionAction( Command.create(CharUtils.lockControls,player,false) ) );

				blockGateChain.execute();

			} // End-if.

		} // end func()

		private function blockGateLeave( hitId:String, entityId:String ):void {
				
			// Make sure its the player that entered the stupid guard zone.
			if ( entityId != "player" ) {
				return;
			} //

		} //

		private function enterGateZone( hitId:String, entityId:String ):void {

			// Make sure its the player that entered the stupid guard zone.
			if ( entityId != "player" ) {
				return;
			}

			if ( super.shellApi.checkEvent( virusEvents.DELIVERING_FALAFEL ) ) {

				// allow enter.

			} else {

				// clip in scene where player walks back to.
				var leftStand:MovieClip = this._hitContainer["leftGateStand"];

				SceneUtil.lockInput( this, true );
				// directionTargetX faces the guard.
				CharUtils.moveToTarget( player, leftStand.x, leftStand.y, true, playerBlocked ).setDirectionOnReached( "", rightGateStand.x );
				// have the guard stop the player - this should trigger some talky from the xml.
				super.shellApi.triggerEvent( "block_entrance" );

			} //

		} //

		private function playerBlocked( e:Entity ):void {

			SceneUtil.lockInput( this, false );

		} //

		// Try to take a photo of the Joe guy.
		private function tryTakePhoto():void {
	
			// First check that the right player is in the way, etc. etc.
			var jSpatial:Spatial = joe.get( Spatial );
			var pSpatial:Spatial = player.get( Spatial );

			var del:Number = pSpatial.y - jSpatial.y;
			if ( Math.abs( del ) <= 30 ) {

				del = pSpatial.x - jSpatial.x;
				if ( Math.abs(del) <= 200 ) {

					if ( del > 0 ) {
						CharUtils.setDirection( player, false );
					} else {
						CharUtils.setDirection( player, true );
					} //

					takePhoto();
					return;

				} //

			} //

			// Say can't take photo:
			( player.get( Dialog ) as Dialog ).sayById( "noPicture" );

		} //

		private function takePhoto():void {

			var actionChain:ActionChain = new ActionChain( this );

			actionChain.lockInput = true;
			
			actionChain.addAction( new SetSkinAction( player, SkinUtils.ITEM, "camera", false, true ) );
			actionChain.addAction( new TalkAction( player, "itsBucky" ) );
			actionChain.addAction( new AnimationAction( player, TakePhoto, "trigger" ) );
			
			actionChain.execute( mistakenIdentity );	
		}
		
		private function mistakenIdentity( chain:ActionChain ):void
		{
			super.shellApi.triggerEvent( "itsBucky" );
			
			var actionChain:ActionChain = new ActionChain( this );
			
			actionChain.lockInput = true;
			
			actionChain.addAction( new TalkAction( joe, "imJoe" ) );
			actionChain.addAction( new TalkAction( player, "myMistake" ) );

			actionChain.execute( takePhotoComplete );
			(getGroupById(PhotoGroup.GROUP_ID) as PhotoGroup).onEventTriggered(virusEvents.TOOK_JOES_PHOTO);

			/*CharUtils.setAnim( player, TakePhoto );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "Camera", false );
			TimelineUtils.onLabel( player, "trigger", takePhotoComplete );*/

		} //

		private function takePhotoComplete( chain:ActionChain ):void {

			shellApi.getItem( "photo", null, true );
			SkinUtils.getSkinPart(this.player, SkinUtils.ITEM).revertValue();
			SceneUtil.lockInput( this, false );

		} // End function takePhotoComplete()

		private function initComputerScreens():void {
 
			var i:int = 0;
			var screen:MovieClip;
			var entity:Entity;

			var tl:Timeline;

			computers = new Vector.<ComputerScreen>();

			screen = super._hitContainer[ "computer"+i ];
			while ( screen != null ) {

				entity = TimelineUtils.convertAllClips( screen, null, this );
				tl = entity.get( Timeline );
				tl.looped = true;
				tl.playing = true;

				//makeComputerScreen( screen );
				i++;
				screen = super._hitContainer[ "computer"+i ];

			} //

		} //

		private function initChars():void {

			joe = this.getEntityById( "joe" );

			falafelGuy = this.getEntityById( "falafelGuy" );
			
			npcWalker = this.getEntityById( "walker" );

			npcs = new Vector.<Entity>();
			
			var i:int = 0;
			var e:Entity = this.getEntityById( "npc" + i );
			while( e != null ) {
				
				npcs.push( e );
				i++;
				e = this.getEntityById("npc"+i);
				
			} // end-while.

			CharUtils.setAnim( npcs[0], Think, false );
			CharUtils.setAnim( npcs[1], KeyboardTyping, false );
			CharUtils.setAnim( npcs[2], Think, false );
			CharUtils.setAnim( npcs[3], Grief, false );

		} // end initChars()

		private function putWalkerAtDesk():void {

			var stand:MovieClip = this._hitContainer["npcFinish"];

			var s:Spatial = npcWalker.get( Spatial );
			var mc:MovieClip = npcWalker.get( Display ).displayObject as MovieClip;

			mc.x = s.x = stand.x;
			mc.y = s.y = stand.y;

			var e:Edge = npcWalker.get( Edge );
			if ( e ) {
				mc.y = s.y -= e.rectangle.bottom;
			}

			SimpleUtils.removeColliders( npcWalker );

		} //

		override protected function addCharacterDialog( container:Sprite ):void {

			// custom dialog entity MUST be added here so that dialog from the xml gets assigned to it.
			makeGuard();
			super.addCharacterDialog( container );

		} //

		private function makeGuard():void {

			var mc:MovieClip = _hitContainer["guard"];
			var display:Display = new Display( mc );

			var dialog:Dialog = new Dialog();
			dialog.faceSpeaker = true;

			guard = new Entity()
				.add( display )
				.add( new Spatial( mc.x, mc.y ) )
				.add( dialog )
				.add( new Id( "guard" ) );

			this.addEntity( guard );

		} //

	} // class
} // package