package game.scenes.virusHunter.condoInterior{

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.Dialog;
	import game.components.motion.MotionControl;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Knock;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.condoInterior.creators.FountainCreator;
	import game.scenes.virusHunter.condoInterior.popups.CondoMailPopup;
	import game.scenes.virusHunter.condoInterior.popups.SearchPopup;
	import game.scenes.virusHunter.condoInterior.systems.SimpleUpdateSystem;
	import game.scenes.virusHunter.joesCondo.components.ActionClick;
	import game.scenes.virusHunter.joesCondo.creators.ClipCreator;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionCommand;
	import game.systems.actionChain.ActionList;
	import game.systems.actionChain.ActionExecutionSystem;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.EventAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.hit.ZoneHitSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;

	public class CondoInterior extends PlatformerGameScene {

		//public const HORN_SOUND_URL:String = "";

		private var virusEvents:VirusHunterEvents;

		private var clipCreator:ClipCreator;
		//private var hornSound:*;

		/**
		 * This will trigger when a wrong door is clicked.
		 */
		private var wrongDoorAction:ActionList;

		public function CondoInterior() {

			super();

		} //

		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void {

			super.groupPrefix = "scenes/virusHunter/condoInterior/";

			super.init(container);

		} //
		
		// initiate asset load of scene specific assets.
		override public function load():void {

			super.load();

		} //

		// all assets ready
		override public function loaded():void {

			// add the execution system so actions can be executed outside an Action chain.
			this.addSystem( new ActionExecutionSystem(), SystemPriorities.update );
			this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );
			this.addSystem( new ZoneHitSystem(), SystemPriorities.update );

			virusEvents = super.events as VirusHunterEvents;

			clipCreator = new ClipCreator( this );

			initMail();
			initDoors();
			initCondoDoor();
			initFountain();
			initHorn();

			super.loaded();

		} //

		/*private function testBitmaps():void {

			var mc:MovieClip = this._hitContainer["testRotate"];

			var theta:Number = mc.rotation * Math.PI/180;
			var cos:Number = Math.cos( theta );
			var sin:Number = Math.sin( theta );

			var bounds:Rectangle = mc.getBounds( mc );

			mc.rotation = -165;
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmap( mc, false, 0 );

			var bitmap:Bitmap = this._hitContainer.getChildAt( this._hitContainer.numChildren-1 ) as Bitmap;
			if ( bitmap == null ) {
				trace( "NULL" );
				return;
			}

		} //*/

		private function actDone( action:ActionCommand ):void {
			//trace( "DONE DONE DONE" );
		} //

		// Let the player go through the mail and find stuff.
		// Using a clickObject here is overkill; I was merely testing the functionality.
		private function initMail():void {

			if ( !shellApi.checkEvent( virusEvents.SEARCHED_MAIL ) ) {

				clipCreator.createActionClick( this._hitContainer["mailClick"], new CallFunctionAction( this.reachedMail ) );

			} else {

				this._hitContainer.removeChild( this._hitContainer["mailClick"] );

			} // end-if.

		} //

		private function reachedMail():void {

			var popup:CondoMailPopup;

			if ( shellApi.checkHasItem( "dossier" ) ) {

				popup =  super.addChildGroup( new CondoMailPopup( "mailSearch.swf", this.groupPrefix, super.overlayContainer, true ) ) as CondoMailPopup;
				popup.onSearchComplete = popupDone;

			} else {

				popup =  super.addChildGroup( new CondoMailPopup( "mailSearch.swf", this.groupPrefix, super.overlayContainer ) ) as CondoMailPopup;

			} // end-if.

			popup.id = "condoMailPopup";

		} //

		private function popupDone( popup:SearchPopup ):void {

			shellApi.completeEvent( virusEvents.SEARCHED_MAIL );
			popup.removed.addOnce( this.sayStockmanFits );
			popup.close();

		} //

		private function sayStockmanFits( group:Group ):void {
			var d:Dialog = player.get( Dialog );
			d.sayById( "say_stockman_fits" );
		} //

		// user can't open the door right away. events have to happen first.
		private function initCondoDoor():void {

			var condoExit:Entity = super.getEntityById( "condoExit" );

			// Remove standard door listeners and add custum listener
			SceneInteraction(condoExit.get(SceneInteraction)).reached.removeAll();
			SceneInteraction(condoExit.get(SceneInteraction)).reached.add( reachedCondoExit );

		} //

		private function initDoors():void {

			var i:int = 0;
			var door:MovieClip = this._hitContainer["wrongDoor"+i];

			wrongDoorAction = new ActionList();
			wrongDoorAction.lockInput = false;
			wrongDoorAction.addAction( new EventAction( this.shellApi, "doorKnock" ) );
			wrongDoorAction.addAction( new AnimationAction( player, Knock, "ending" ) );
			wrongDoorAction.addAction( new TalkAction( player, "noAnswer" ) );

			var tip:Entity;

			// All the doors can actually use the same click action.
			var actionClick:ActionClick = new ActionClick( this, wrongDoorAction );
			var e:Entity;
	
			while ( door != null ) {

				door.alpha = 0;
				e = clipCreator.createSpatialDisplay( door );
				e.add( actionClick );

				tip = ToolTipCreator.create( ToolTipType.CLICK, door.x, door.y );
				EntityUtils.addParentChild( tip, e );
				this.addEntity( tip );

				i++;
				door = this._hitContainer["wrongDoor"+i];

			} //

		} // initDoors()

		// player is at the condo door.
		private function reachedCondoExit( interactor:Entity, door:Entity ):void {

			if ( interactor != player ) {
				return;
			}

			if ( shellApi.checkEvent( virusEvents.SEARCHED_MAIL ) ) {

				// knock on condo door -> say no answer, at work.
				CharUtils.setAnim( player, Knock, false );

				super.shellApi.triggerEvent( "doorKnock" );
				TimelineUtils.onLabel( player, "ending", knockComplete );
				MotionControl( super.player.get( MotionControl ) ).lockInput = true;				// lock controls

			} else {

				wrongDoorAction.run( this, null );

			} // end-if.

		} //

		// Now player says noone is there. Just trigger an event that will make something happen
		// from the xml.
		private function knockComplete():void {

			MotionControl( super.player.get( MotionControl ) ).lockInput = false;				// lock controls
			super.shellApi.triggerEvent( "joeAtWork" );


		} //

		// It seems there is some way to do this with SceneInteractions via xml
		// though at the moment I'm not sure how.
		private function initHorn():void {

			var horn:Entity = clipCreator.createSceneInteractor( this._hitContainer["hornClick"], hornReached );

		} //

		private function initFountain():void {

			var fountMaker:FountainCreator = new FountainCreator();
			
			var fountain:Entity = fountMaker.createFountain( _hitContainer["fountain"], _hitContainer["fountainClick"],
				super.getAsset("droplet.swf") as MovieClip );
			this.addEntity( fountain );

		} //

		public function hornReached( arriver:Entity, theHorn:Entity ):void {

			super.shellApi.triggerEvent( "honkHorn" );

		} //

	} // class

} // package