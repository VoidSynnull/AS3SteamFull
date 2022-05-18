package game.scenes.survival1.woods
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.motion.MotionTarget;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Float;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.item.SceneItemData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.scene.labels.LabelData;
	import game.data.sound.SoundType;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.islands.survival.SetHandParts;
	import game.particles.emitter.PoofBlast;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.shared.SurvivalScene;
	import game.scenes.survival1.shared.components.ThermostatGaugeComponent;
	import game.scenes.survival1.woods.components.WoodPecker;
	import game.scenes.survival1.woods.states.WoodPeckerBeginFlightState;
	import game.scenes.survival1.woods.states.WoodPeckerFlyState;
	import game.scenes.survival1.woods.states.WoodPeckerIdleState;
	import game.scenes.survival1.woods.states.WoodPeckerLandState;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.entity.character.states.CharacterState;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class Woods extends SurvivalScene
	{
		public function Woods()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{				
			super.groupPrefix = "scenes/survival1/woods/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			_events = super.events as Survival1Events;
			
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{		
			// if first time entering scene, place hanging from tree
			if(!this.shellApi.checkEvent(_events.BEGIN_LANDING))
			{
				crashLanding();
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["straps"]);
				removeEntity(getEntityById("stuck"));
			}			
			
			setupWoodPecker();
			
			// Set up branch that breaks
			if( this.shellApi.checkEvent(_events.BRANCH_BROKEN) )
			{
				removeBranch()
				if( !this.shellApi.checkHasItem(_events.LOGS))
				{
					showLogs();
				}
			}	
			else
			{
				setupBranch();
			}
			
			// move handbook behind player
			var handbook:Entity = getEntityById(_events.SURVIVAL_HANDBOOK);
			if( handbook )
			{
				DisplayUtils.moveToOverUnder( EntityUtils.getDisplayObject( handbook), EntityUtils.getDisplayObject( super.player), false );
			}
			
			if(!this.shellApi.checkHasItem(_events.NEST))
			{
				var nestEntity:Entity = getEntityById("nest");
				nestEntity.remove(Item);
				setupSquirrel();
			}
			else
			{
				_hitContainer.removeChild( _hitContainer["squirrel"] );
				_hitContainer.removeChild( _hitContainer["squirrelRun"] );
			}

			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(2970, 1485),"minibillboard/minibillboardSmallLegs.swf");	
			
			super.loaded();
			
			// WARNING :: Not sure what teh below does, commented out, need to ask Scott W - bard
			/*
			if(!this.shellApi.checkEvent(_events.BEGIN_LANDING))
			{
				// QUESTION :: What's this all about? - bard
				var specialAbility:SpecialAbilityControl = new SpecialAbilityControl();
				var specialAbilityData:SpecialAbilityData = new SpecialAbilityData( SetHandParts );
				specialAbility.addSpecial( specialAbilityData );
				specialAbility.trigger = true;
				player.add( specialAbility );
			}
			*/
		}
		
		private function crashLanding():void
		{	
			SkinUtils.setEyeStates(player, EyeSystem.OPEN, EyeSystem.DOWN);
			SkinUtils.setSkinPart(player, SkinUtils.MOUTH, "scuba");
			getEntityById("tree").remove(Platform);
			
			CharUtils.setAnim(player, Float);
			CharUtils.lockControls(player, true, true);
			Motion(player.get(Motion)).zeroMotion("y");
			
			_straps = EntityUtils.createSpatialEntity(this, _hitContainer["straps"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(_straps);
			DisplayUtils.moveToTop(_straps.get(Display).displayObject);
			
			var spatial:Spatial = player.get( Spatial );
			spatial.y = 415;
			spatial.x = 850;
			
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("you're stranded in the wilderness! survive the night by building a fire", "start");
			introPopup.configData("introPopup.swf", "scenes/survival1/woods/introPopup/");
			introPopup.popupRemoved.addOnce(introPopupClosed);
			addChildGroup(introPopup);		
		}
		
		private function introPopupClosed():void
		{
			var strapButton:Entity = ButtonCreator.createButtonEntity(_hitContainer["strapButton"], this, openingClick);	
			ToolTipCreator.addToEntity(strapButton);
			var specialAbility:SpecialAbilityControl = player.get( SpecialAbilityControl );
			
			if( specialAbility )
			{
				var specialAbilityData:SpecialAbilityData = specialAbility.getSpecialByClass( SetHandParts );
				if( specialAbilityData )
				{										
					shellApi.specialAbilityManager.removeSpecialAbility(super.shellApi.player, specialAbilityData.id);
				}			
			}
		}
		
		private function openingClick(entity:Entity):void
		{
			removeEntity(getEntityById("stuck"));
			this.removeEntity(entity, true);
			SceneUtil.lockInput(this, true, false);
			
			var playerFSM:FSMControl = player.get(FSMControl);
			playerFSM.setState(CharacterState.STAND);
			CharUtils.stateDrivenOn(player);		
			
			playerFSM.stateChange = new Signal();
			playerFSM.stateChange.add(playerChange);
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "game_tile_clip_01.mp3" );
		}
		
		private function playerChange(state:String, entity:Entity):void
		{
			if(state == CharacterState.LAND)
			{				
				removeEntity(_straps, true);
				
				var playerSpatial:Spatial = player.get(Spatial);
				snowPuff(30, 15, playerSpatial.x, playerSpatial.y + 40);
				CharUtils.setAnim(this.player, Dizzy);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(sayDialog, "rough_landing", Command.create(standPlayer, true))));	
				
				var playerFSM:FSMControl = player.get(FSMControl);
				playerFSM.stateChange.removeAll();
			}
		}
		
		private function standPlayer(dialogData:DialogData, tremble:Boolean = false):void
		{
			CharUtils.setAnim(player, Stand);
			
			if(tremble)
			{
				this.shellApi.triggerEvent(_events.BEGIN_LANDING, true);
				SceneUtil.addTimedEvent(this, new TimedEvent(.25, 1, tremblePlayer));
			}
			else
			{
				giveControlBack();
				CharUtils.stateDrivenOn(player);
			}
		}
		
		private function tremblePlayer():void
		{
			getEntityById("tree").add(new Platform());
			CharUtils.setAnim(player, Tremble);
			sayDialog("its_cold", standPlayer);
			
			var gauge:ThermostatGaugeComponent = player.get( ThermostatGaugeComponent );
			gauge.active = true;
		}
		
		private function setupBranch():void
		{		
			var clip:MovieClip = _hitContainer["breakingBranch"];
			_breakingBranch = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip( clip, this, _breakingBranch, null, false );
			super.convertToBitmap( clip.content.content );
			
			var branchZone:Zone = getEntityById("breakZone").get(Zone);
			branchZone.pointHit = true;
			branchZone.inside.add(breakBranch);
		}
		
		private function breakBranch(zoneId:String, charId:String):void
		{
			if(player.get(Motion).velocity.y >= 0)
			{
				var branchZone:Zone = getEntityById("breakZone").get(Zone);
				branchZone.inside.removeAll();
				
				shellApi.triggerEvent(_events.BRANCH_BROKEN, true);
				var timeline:Timeline = _breakingBranch.get(Timeline);
				timeline.gotoAndPlay("break");
				timeline.handleLabel("fall", Command.create(removeEntity, getEntityById("looseBranch")));
				timeline.handleLabel("end", branchDropped);
			}
		}
		
		private function branchDropped():void
		{
			snowPuff( 10, 50, 1942, 1825 );
			showLogs();
			removeBranch();
		}
		
		private function snowPuff(amnt:int, size:Number, xLoc:int, yLoc:int):void
		{
			var poofBlast:PoofBlast = new PoofBlast();
			poofBlast.init(amnt, size, 0xF5F4F1, .4, .5);
			EmitterCreator.create(this, _hitContainer, poofBlast, xLoc, yLoc);
		}
		
		// Show the logs item after the branch breaks
		private function showLogs():void
		{			
			var logItem:SceneItemData = new SceneItemData();
			logItem.id = "logs";
			logItem.asset = "logs.swf";
			logItem.x = 1942;
			logItem.y = 1823;
			logItem.label = new LabelData();
			logItem.label.text = "Examine";
			logItem.label.type = "click";
			
			var itemGroup:ItemGroup = this.getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			itemGroup.addSceneItemByData(logItem);
		}
		
		private function removeBranch():void
		{
			if( _breakingBranch )
			{
				removeEntity(_breakingBranch, true);
			}
			else
			{
				_hitContainer.removeChild( _hitContainer["breakingBranch"] );
			}
			removeEntity(getEntityById("looseBranch"));
			removeEntity(getEntityById("breakZone"), true);
		}
		
		private function setupSquirrel():void
		{
			_squirrel = EntityUtils.createSpatialEntity(this, _hitContainer["squirrel"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["squirrel"], this, _squirrel);

			_squirrel.get(Timeline).gotoAndPlay("introloop");
			
			var hitCreator:HitCreator = new HitCreator();
			var hitData:HazardHitData = new HazardHitData();
			hitData.type = "squirrelHit";
			hitData.knockBackCoolDown = 1;
			hitData.knockBackVelocity = new Point(2500, 1000);
			_squirrel = hitCreator.makeHit(_squirrel, HitType.HAZARD, hitData, this);
			
			var squirrelZone:Zone = getEntityById("squirrelZone").get(Zone);
			squirrelZone.pointHit = true;
			squirrelZone.entered.add(enteredSquirrelZone);
			
			_squirrelRun = TimelineUtils.convertClip(_hitContainer["squirrelRun"], this);
			_squirrelRun.get(Timeline).gotoAndPlay("groundloop");
			
			var runAwayZone:Zone = getEntityById("squirrelRunZone").get(Zone);
			runAwayZone.entered.addOnce(enteredRunAwayZone);
			
			Sleep(_squirrel.get(Sleep)).ignoreOffscreenSleep = true;
		}
		
		private function setupWoodPecker():void
		{
			_landingLocations = new Array(new Point(380, 1130), new Point(3320, 1115), new Point(1340, 330), new Point(4720, 640));
			_currentSpot = 0;
			
			this.convertContainer(_hitContainer["woodPecker"]);
			
			_woodPecker = EntityUtils.createSpatialEntity(this, _hitContainer["woodPecker"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["woodPecker"], this, _woodPecker);
			//BitmapTimelineCreator.convertToBitmapTimeline(_woodPecker);
			var characterGroup:CharacterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			characterGroup.addTimelineFSM(_woodPecker, true, new <Class>[WoodPeckerIdleState, WoodPeckerBeginFlightState, WoodPeckerFlyState, WoodPeckerLandState], MovieclipState.STAND, false);
			
			var target:MotionTarget = _woodPecker.get(MotionTarget);
			target.targetX = _landingLocations[_currentSpot].x;
			target.targetY = _landingLocations[_currentSpot].y;
			
			FSMControl(_woodPecker.get(FSMControl)).stateChange = new Signal();
			FSMControl(_woodPecker.get(FSMControl)).stateChange.add(woodPeckerStateChange);
			
			var peckerComp:WoodPecker = new WoodPecker();
			peckerComp.flySpeed = 640;
			peckerComp.landDist = 240;
			_woodPecker.add(peckerComp);
			_woodPecker.remove(Sleep);
			_woodPecker.add(new Audio());
			_woodPecker.add(new AudioRange(2000, 0, 1.5, Sine.easeIn));
			
			var birdEntity:Entity = getEntityById("birdZone");
			var zone:Zone = birdEntity.get(Zone);
			birdEntity.get(Display).isStatic = false;
			birdEntity.managedSleep = true;
			
			zone.entered.addOnce(enteredBirdZone);
		}
		
		private function enteredBirdZone(zoneId:String, characterId:String):void
		{
			SceneUtil.lockInput(this, true);
			
			// If its the first time, lock the input and show the bird moving, else just wait until
			// the bird is offscreen
			SceneUtil.setCameraTarget(this, _woodPecker, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, giveControlBack));			
			_currentSpot++;
			
			var zoneEntity:Entity = this.getEntityById(zoneId);
			var newPoint:Point = _landingLocations[_currentSpot];
			var zoneSpatial:Spatial = zoneEntity.get(Spatial);
			zoneSpatial.x = newPoint.x;
			zoneSpatial.y = newPoint.y;
			
			var target:MotionTarget = _woodPecker.get(MotionTarget);
			target.targetX = newPoint.x;
			target.targetY = newPoint.y;
			
			DisplayUtils.moveToTop(_woodPecker.get(Display).displayObject);
		}
		
		// Zone at bottom to make squirrel run up the tree
		private function enteredRunAwayZone(zoneId:String, characterId:String):void
		{
			SceneUtil.lockInput(this, true);
			var squirrelTimeline:Timeline = _squirrelRun.get(Timeline);
			squirrelTimeline.gotoAndPlay("groundstartled");
			squirrelTimeline.handleLabel("gone", Command.create(sayDialog, "squirrel_runs_up", squirrelGone));
		}
		
		private function enteredSquirrelZone(zoneId:String, characterId:String):void
		{
			SceneUtil.lockInput(this, true);
			var squirrelTimeline:Timeline = _squirrel.get(Timeline);
			
			if(_firstSquirrel)
			{
				removeEntity(getEntityById("squirrelRunZone"), true);
				var runtimeline:Timeline = _squirrelRun.get(Timeline);
				runtimeline.gotoAndStop("end");
				
				_firstSquirrel = false;
				squirrelTimeline.gotoAndPlay("noticeplayer");
				squirrelTimeline.handleLabel("growl", Command.create(shellApi.triggerEvent, "squirrel_warning"));
				squirrelTimeline.handleLabel("hidden", Command.create(squirrelHidden, squirrelTimeline));
			}
			else
			{
				squirrelHidden(squirrelTimeline);
			}			
		}
		
		private function squirrelGone(dialogData:DialogData):void
		{
			removeEntity(getEntityById("squirrelRunZone"), true);
			giveControlBack();
		}
		
		// When the squirrel is hidden, check to see if player has moved woodpecker
		// into the correct location
		private function squirrelHidden(squirrelTimeline:Timeline):void
		{
			if(_currentSpot != _landingLocations.length - 1)
			{
				squirrelTimeline.gotoAndPlay("attack");
				squirrelTimeline.handleLabel("hidden", giveControlBack);
			}
			else
			{
				_squirrel.remove(Hazard);
				squirrelTimeline.gotoAndPlay("solved");
				squirrelTimeline.handleLabel("end", squirrelFled);
				shellApi.triggerEvent("squirrel_frustrated");
			}
		}
		
		// Once the squirrel flees make the nest and item and remove squirrel leftovers
		private function squirrelFled():void
		{
			var nest:Entity = this.getEntityById("nest");
			if(nest) 
				nest.add(new Item());
			
			this.getEntityById("squirrelZone").get(Zone).entered.removeAll();
			this.removeEntity(getEntityById("squirrelZone"), true);
			giveControlBack();				
		}
		
		// Wood peckers listener for state changes
		private function woodPeckerStateChange(state:String, entity:Entity):void
		{
			var audio:Audio = _woodPecker.get(Audio);
			audio.stopAll(SoundType.EFFECTS);
			
			if(state == MovieclipState.STAND)
			{
				if(_landing)
				{
					_landing = false;
					if(_currentSpot < _landingLocations.length - 1)
					{
						var zone:Zone = getEntityById("birdZone").get(Zone);
						zone.entered.addOnce(enteredBirdZone);
					}	
				}
			}
			
			if(state == MovieclipState.LAND)
			{
				_landing = true;
			}
		}
		
		// function to make the player say a dialog
		private function sayDialog(id:String, handler:Function):void
		{
			player.get(Dialog).sayById(id);
			CharUtils.dialogComplete(player, handler);	
		}
		
		// give any possible control back that was stripped away
		private function giveControlBack():void
		{
			SceneUtil.lockInput(this, false, false);
			CharUtils.lockControls(player, false, false);
			SceneUtil.setCameraTarget(this, player);			
		}
		
		private var _events:Survival1Events;
		private var _woodPecker:Entity;
		private var _landingLocations:Array;
		private var _currentSpot:Number;
		private var _landing:Boolean = false;
		private var _breakingBranch:Entity;
		private var _squirrel:Entity;
		private var _squirrelRun:Entity;
		private var _firstSquirrel:Boolean = true;
		private var _nestItem:Item;
		private var _straps:Entity;
	}
}
