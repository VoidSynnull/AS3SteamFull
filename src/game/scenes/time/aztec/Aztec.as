package game.scenes.time.aztec{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.TransportGroup;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Hazard;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.scene.HitCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.aztec.states.AztecAttackState;
	import game.scenes.time.aztec.states.AztecHitRetreatState;
	import game.scenes.time.aztec.states.AztecRetreatState;
	import game.scenes.time.aztec.states.AztecStandState;
	import game.scenes.time.aztec.states.AztecStompState;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * @author Scott Wszalek
	 */
	public class Aztec extends PlatformerGameScene
	{
		public function Aztec()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/aztec/";
			
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
			
			_events = super.events as TimeEvents;
			setupSunstone();
			setupAttackers(NUM_ATTACKERS);
			switchAttackersMode(NUM_ATTACKERS, true);
			placeTimeDeviceButton();
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			// was the sunstone returned?
			if(super.shellApi.checkItemUsedUp(_events.SUNSTONE))
			{
				showSunstone(true);
				
				var char2:Entity = super.getEntityById("char2");
				var char3:Entity = super.getEntityById("char3");
				
				CharUtils.setAnim(char2, Stand, false, 0, 0, true);
				CharUtils.setAnim(char3, Stand, 0, 0, 0, true);
			}
			
			// ever had mask
			if(super.shellApi.checkItemEvent(_events.WARRIOR_MASK))
			{
				hideMask();
			}
			
			//ever had googles
			if(super.shellApi.checkItemEvent(_events.GOGGLES))
			{
				hideGoggles();
			}
			
			// Check to see if the warrior mask is already on
			if(SkinUtils.getLook(player).getValue(SkinUtils.FACIAL)== "aztecmask")
			{	
				switchAttackersMode(NUM_ATTACKERS, false);
				super.shellApi.triggerEvent(_events.WARRIOR_MASK_ON);
			}
			else
			{
				switchAttackersMode(NUM_ATTACKERS, true);
			}
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.HAS_ITEM + _events.WARRIOR_MASK)
			{
				hideMask();
			}
			else if(event == GameEvent.GOT_ITEM + _events.GOGGLES)
			{
				hideGoggles();
			}
			else if(event == _events.WARRIOR_MASK_OFF)
			{
				switchAttackersMode(NUM_ATTACKERS, true);
			}
			else if(event == _events.WARRIOR_MASK_ON)
			{
				switchAttackersMode(NUM_ATTACKERS, false);
			}
			else if(event == GameEvent.GOT_ITEM + _events.SUNSTONE)
			{	
				if(!super.shellApi.checkHasItem(_events.SUNSTONE) && !_returnedBool)
				{
					// If the sunstone is returned then show it and have the king celebrate
					// Also stop the king and queen from crying
					showSunstone();
					shellApi.triggerEvent(_events.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
										
					var char2:Entity = super.getEntityById("char2");
					var char3:Entity = super.getEntityById("char3");
					
					CharUtils.setAnim(char2, Score, false, 0, 0, true);
					RigAnimation( CharUtils.getRigAnim( char2) ).ended.add( onCelebrateEnd );
					CharUtils.setAnim(char3, Stand, 0, 0, 0, true);
				}
			}
		}

		private function onCelebrateEnd( anim:Animation = null ):void
		{
			var char2:Entity = super.getEntityById("char2");
			CharUtils.setAnim(char2, Stand, false, 0, 0, true);	
		}
		
		private function setupAttackers(numAttackers:int = 0):void
		{
			for (var i:int = 1; i <= numAttackers; i++) 
			{
				var attackerEntity:Entity = super.getEntityById("attacker" + i);
				attackerEntity.add(new Motion());
				attackerEntity.add(new Sleep(false, true));
				var attackerSpatial:Spatial = attackerEntity.get(Spatial);
				
				var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
				charGroup.addFSM( attackerEntity );
				MotionTarget(attackerEntity.get(MotionTarget)).targetSpatial = this.player.get(Spatial);
				MotionTarget(attackerEntity.get(MotionTarget)).useSpatial = false;
				MotionControl(attackerEntity.get(MotionControl)).lockInput = true;
				MotionControl(attackerEntity.get(MotionControl)).forceTarget = true;
				
				var fsmControl:FSMControl = new FSMControl(super.shellApi);
				fsmControl.stateChange = new Signal();
				fsmControl.stateChange.add(onStateChange);
				attackerEntity.add( fsmControl );
				
				var stateCreator:FSMStateCreator = new FSMStateCreator();
				stateCreator.createCharacterStateSet( new <Class>[AztecStandState, AztecAttackState, AztecRetreatState, AztecHitRetreatState, AztecStompState], attackerEntity ); 
				
				AztecAttackState( fsmControl.getState( "attack" ) ).originalLocation = new Point(attackerSpatial.x, attackerSpatial.y);
				AztecRetreatState( fsmControl.getState( "retreat" ) ).originalLocation = new Point(attackerSpatial.x, attackerSpatial.y);
				fsmControl.setState("stand");
			}
		}
		
		// to turn the attackers on and off 
		private function switchAttackersMode(numAttackers:int = 0, attack:Boolean = false):void
		{
			for (var i:int = 1; i <= numAttackers; i++) 
			{
				var attackerEntity:Entity = super.getEntityById("attacker" + i);
				var fsmControl:FSMControl = attackerEntity.get(FSMControl);
				
				if(!attack)
				{
					(fsmControl.getState("stand") as AztecStandState).maskOn = true;
					(fsmControl.getState("stomp") as AztecStompState).maskOn = true;
					(fsmControl.getState("retreat") as AztecRetreatState).maskOn = true;
					(fsmControl.getState("attack") as AztecAttackState).maskOn = true;
					attackerEntity.remove(Hazard);
				}
				else
				{
					(fsmControl.getState("stand") as AztecStandState).maskOn = false;
					(fsmControl.getState("stomp") as AztecStompState).maskOn = false;
					(fsmControl.getState("retreat") as AztecRetreatState).maskOn = false;
					(fsmControl.getState("attack") as AztecAttackState).maskOn = false;
					
					// add hazard
					var hitCreator:HitCreator = new HitCreator();					
					var hitData:HazardHitData = new HazardHitData();
					hitData.type = "guardHit";
					hitData.knockBackCoolDown = .75;
					hitData.knockBackVelocity = new Point(1800, 500);
					hitData.velocityByHitAngle = false;
					attackerEntity = hitCreator.makeHit(attackerEntity, HitType.HAZARD, hitData, this);
				}
			}
		}
		
		private function onStateChange(type:String, entity:Entity):void
		{
			if(type == "stomp")
			{
				super.shellApi.triggerEvent("warrior_angry");
			}
			else if(type == "hit_retreat")
			{
				_wait = true;
				super.shellApi.triggerEvent("warrior_whack");
			}
			else if(type == "stand" && _wait)
			{
				_wait = false;
				var fsmControl:FSMControl = entity.get(FSMControl);
				(fsmControl.getState(type) as AztecStandState).waitCounter = 4;
			}
		}
		
		private function setupSunstone():void
		{
			var sunstone:MovieClip = this._hitContainer["sunstone"];
			_sunstoneEntity = TimelineUtils.convertClip(sunstone, this);
		}
		
		private function showSunstone(instant:Boolean = false):void
		{
			_returnedBool = true;
			var timeline:Timeline = _sunstoneEntity.get(Timeline);
			
			if(instant)
				timeline.gotoAndStop("stoneFixed");
			else
				timeline.gotoAndPlay("showStone");
		}
		
		private function hideMask():void
		{
			var charMask:Entity = super.getEntityById("char9");
			SkinUtils.setSkinPart(charMask, SkinUtils.ITEM, "empty", true);
		}
		
		private function hideGoggles():void
		{
			var charGoggles:Entity = super.getEntityById("attacker1");
			SkinUtils.setSkinPart(charGoggles, SkinUtils.FACIAL, "empty", true);
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(_events.TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		private var timeButton:Entity;
		
		private var _sunstoneEntity:Entity;
		private var _events:TimeEvents;
		private const NUM_ATTACKERS:int = 2;
		private var _wait:Boolean = false;
		private var states:Vector.<Class>
		private var _returnedBool:Boolean = false;
	}
}