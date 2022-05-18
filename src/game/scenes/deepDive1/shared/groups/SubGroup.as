package game.scenes.deepDive1.shared.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Player;
	import game.components.entity.character.Talk;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.character.CharacterData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.game.GameEvent;
	import game.scene.template.CharacterGroup;
	import game.scenes.deepDive1.shared.creators.SubCreator;
	import game.scenes.deepDive1.shared.systems.SubCameraSystem;
	import game.scenes.deepDive1.shared.systems.SubMotionSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.EyeSystem;
	import game.systems.hit.MovieClipHitSystem;
	import game.systems.hit.ResetColliderFlagSystem;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.ui.ProgressBarSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class SubGroup extends Group
	{
		public function SubGroup()
		{
			super();
			this.id = GROUP_ID;
		}
		
		public function setupGroup( group:DisplayGroup, container:DisplayObjectContainer, subId:String = null, characterId:String = null, handler:Function = null, lookData:LookData = null):void
		{
			_container = container;
			_group = group;
			
			// add a container for all ship particles
			_shipParticleContainer = new Sprite();
			container.addChild(_shipParticleContainer);
			_shipParticleContainer.mouseChildren = false;
			_shipParticleContainer.mouseEnabled = false;
			
			_subCreator = new SubCreator();

			// add it as a child group to give it access to systemManager.
			group.addChildGroup(this);
			
			group.addSystem(new SubCameraSystem(), SystemPriorities.update);
			group.addSystem(new SubMotionSystem(), SystemPriorities.inputComplete);
			group.addSystem(new RotateToTargetSystem(), SystemPriorities.move);
			group.addSystem(new MovieClipHitSystem(), SystemPriorities.resolveCollisions);
			group.addSystem(new ResetColliderFlagSystem(), SystemPriorities.resetColliderFlags);
			
			group.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);  // maps control input position to motion components.
			group.addSystem(new MotionSystem(), SystemPriorities.move);						// updates velocity based on acceleration and friction.
			group.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			group.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);    // maps input button presses to acceleration.
			group.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			group.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
			group.addSystem(new NavigationSystem(), SystemPriorities.update);			    // This system moves an entity through a series of points for autopilot.
			group.addSystem(new DestinationSystem(), SystemPriorities.update);	
			group.addSystem(new TargetEntitySystem(), SystemPriorities.update);	
			group.addSystem(new ProgressBarSystem(), SystemPriorities.lowest);
			
			// load sub asset
			super.shellApi.loadFile(super.shellApi.assetPrefix + "scenes/deepDive1/shared/sub.swf", subLoaded, subId, characterId, handler, lookData);
		}

		private function subLoaded(clip:MovieClip, subId:String = null, characterId:String = null, handler:Function = null, lookData:LookData = null):void
		{
			// create sub Entity
			var subEntity:Entity = _subCreator.create( _group, _container, clip, shellApi.profileManager.active.lastX, shellApi.profileManager.active.lastY, shellApi.profileManager.active.lastDirection, Scene(_group).sceneData.bounds, _shipParticleContainer, subId );
			super.shellApi.player = subEntity;
			subEntity.add(new Player());
				
			// create character Entity, this goes inside the sub
			var charGroup:CharacterGroup = new CharacterGroup();
			charGroup.setupGroup(_group);				
			var characterData:CharacterData = new CharacterData();
			characterData.id = characterId;
			characterData.type = CharacterCreator.TYPE_PORTRAIT;
			characterData.event = GameEvent.DEFAULT;
			
			if( lookData == null )
			{
				var playerLook:PlayerLook = shellApi.profileManager.active.look;
				lookData = ( playerLook != null ) ? new LookConverter().lookDataFromPlayerLook(shellApi.profileManager.active.look) : new LookData();	 
			}
			characterData.look = lookData		

			charGroup.createDummyFromData(characterData, subEntity.get(Display).displayObject["content"]["char"], _group, Command.create(onCharacterLoaded, handler));
		}
		
		private function onCharacterLoaded( charEntity:Entity, handler:Function = null ):void
		{
			ToolTipCreator.removeFromEntity(charEntity);
			
			charEntity.add(new Talk());
			var dialog:Dialog = new Dialog();
			//dialog.balloonTarget = super.shellApi.player.get(Spatial);
			charEntity.add(dialog);
			
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_LOW )
			{
				SkinUtils.setEyeStates( charEntity, EyeSystem.CASUAL_STILL, EyeSystem.FRONT, true );
			}

			SceneUtil.addTimedEvent( this, new TimedEvent( 6, 1, Command.create(bitmapParts, charEntity) ) ).countByUpdate = true;
			super.groupReady();
			
			if( handler != null )
			{
				handler();
			}
		}
		
		private function bitmapParts( charEntity:Entity ):void
		{
			
			// if quality of low bitmap entire character
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_LOW )
			{
				_group.convertToBitmap( EntityUtils.getDisplayObject(charEntity) );
				// TODO :: should remove all parts except for mouth...
			}
			else	
			{
				CharUtils.bitmapPart(charEntity, CharUtils.ARM_BACK);
				CharUtils.bitmapPart(charEntity, CharUtils.ARM_FRONT);
				CharUtils.bitmapPart(charEntity, CharUtils.HAND_BACK);
				CharUtils.bitmapPart(charEntity, CharUtils.HAND_FRONT);
				CharUtils.bitmapPart(charEntity, CharUtils.HEAD_PART);
				CharUtils.bitmapPart(charEntity, CharUtils.BODY_PART);
				CharUtils.bitmapPart(charEntity, CharUtils.HAIR);
				CharUtils.bitmapPart(charEntity, CharUtils.ITEM);
				CharUtils.bitmapPart(charEntity, CharUtils.OVERPANTS_PART);
				CharUtils.bitmapPart(charEntity, CharUtils.OVERSHIRT_PART);
				CharUtils.bitmapPart(charEntity, CharUtils.MARKS_PART);
				CharUtils.bitmapPart(charEntity, CharUtils.PACK);
				CharUtils.bitmapPart(charEntity, CharUtils.FACIAL_PART);
				CharUtils.bitmapPart(charEntity, CharUtils.PANTS_PART);
				CharUtils.bitmapPart(charEntity, CharUtils.SHIRT_PART);
			}
		}

		private var _container:DisplayObjectContainer;
		private var _shipParticleContainer:DisplayObjectContainer;
		private var _subCreator:SubCreator;
		private var _loading:int = 0;
		private var _group:DisplayGroup;
		public static const GROUP_ID:String = "subGroup";
		
	}
}