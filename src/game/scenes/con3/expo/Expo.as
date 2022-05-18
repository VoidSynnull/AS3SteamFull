package game.scenes.con3.expo
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.group.TransportGroup;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.MotionControl;
	import game.components.timeline.BitmapSequence;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.scene.template.ItemGroup;
	import game.scenes.con3.Con3Scene;
	import game.scenes.con3.shared.PortalGroup;
	import game.scenes.map.map.Map;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class Expo extends Con3Scene
	{
//		private var portal:Entity;
		private var _transportGroup:TransportGroup;
		private var _portalGroup:PortalGroup;
		
		public function Expo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/expo/";
			
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
			
			EntityUtils.position(player,677,845);
			CharUtils.setDirection(player, true);
			
			if(!shellApi.checkEvent(GameEvent.HAS_ITEM+_events.MEDAL_CON3)){
				_portalGroup = addChildGroup( new PortalGroup()) as PortalGroup;
				_portalGroup.createPortal( this, _hitContainer );
				
				SceneUtil.lockInput(this, true);
				CharUtils.lockControls( player );
				
				// cause player to float in mid-air
				(player.get(CharacterMotionControl) as CharacterMotionControl).gravity = 0;
				(player.get(Motion) as Motion).zeroMotion();
				
				EntityUtils.position(player,677,680);
				Display(player.get(Display)).alpha = 0;	
				Display(player.get(Display)).visible = true;
				
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, teleportIn ));
			}else{
				_hitContainer.removeChild(_hitContainer["portal"]);
			}
		}
		
		private function teleportIn():void
		{
			_transportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
			
			_portalGroup.portalTransitionIn( transportInCharacter, startEndSequence, _events.PLAYER_THROUGH_PORTAL );
		}
		
		private function transportInCharacter():void
		{
			_transportGroup.transportIn( player, false, .3, addPlayerGravity );
		}
		
		private function addPlayerGravity():void
		{
			// cause player to fall slowly
			(player.get(CharacterMotionControl) as CharacterMotionControl).gravity = MotionUtils.GRAVITY/2;
			
			shellApi.completeEvent( _events.PLAYER_THROUGH_PORTAL );
		}
		
		private function startEndSequence(...p):void
		{
			var leader:Entity = getEntityById("leader");
			var wizard:Entity = getEntityById("wizard");
			var fan:Entity = getEntityById("fan");
			
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new PanAction(wizard, 0.05));
			actions.addAction(new TalkAction(wizard, "best"));
		//	actions.addAction(new PanAction(fan));
			actions.addAction(new TalkAction(fan, "top"));
		//	actions.addAction(new PanAction(leader));
			actions.addAction(new TalkAction(leader, "sorry"));
			actions.addAction(new PanAction(player));
			
			actions.execute(getMedal);
		}
		
		private function getMedal(...p):void 
		{
			//reset player's gravity to standard
			(player.get(CharacterMotionControl) as CharacterMotionControl).gravity = MotionUtils.GRAVITY;
			
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			// NOTE :: Any reason we would already have the item and thus the item wouldn't be shown? - bard
			itemGroup.showAndGetItem( _events.MEDAL_CON3);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.1, 1, medallionReceived));
		}

		private function medallionReceived():void
		{
			shellApi.completedIsland('', showFinalPopup);
		}
		
		private function showFinalPopup(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false, false);
			CharUtils.lockControls( player, false, false );
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
		}
	}
}