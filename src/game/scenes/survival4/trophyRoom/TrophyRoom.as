package game.scenes.survival4.trophyRoom
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.HitTest;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionTarget;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Knock;
	import game.data.animation.entity.character.PourPitcher;
	import game.data.character.LookData;
	import game.data.scene.characterDialog.DialogData;
	import game.particles.emitter.PoofBlast;
	import game.scene.template.CharacterGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival4.Survival4Events;
	import game.scenes.survival4.shared.Survival4Scene;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.HitTestSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.costumizer.CostumizerPop;
	import game.ui.popup.OneShotPopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class TrophyRoom extends Survival4Scene
	{
		public function TrophyRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival4/trophyRoom/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var survival:Survival4Events;
		
		private var tourDialogIds:Array = ["trophies", "forgive me", "ready supper", "meet me"];
		
		private var heads:Array =  		  [ "hyena", "alligator"];
		private var headSounds:Array =	  [HYENA_FALL, GATOR_FALL];
		// x,  y,  rot,    x,  y, rot,
		private var fallPositions:Array = [ 1815, 885, 30, 2150, 900, 135];
		
		private var tourPositions:Array = [ 1000, 2125, 2125];
		
		private var showingTrophies:Boolean = false;
		
		private var lightPosition:int;
		private var trophyPositions:Array = [1325,1650,1875,2050];
		private const TROPHY_TOUR_OFFSET:Number = -75;
		private const ROOM_DARKNESS:Number = .5;
		
		private var tourPosition:int;
		private var tourComplete:Boolean = false;
		private const FELL:String = "_fell";
		private const MP3:String = ".mp3";
		
		private const HYENA_FALL:String = "pick_axe_impact_01";
		private const HYENA_FELL:String = "wood_heavy_impact_01";
		private const GATOR_FALL:String = "metal_impact_21";
		private const STATUE_BREAKS:String = "large_stone_01";
		private const TALLY_HO:String = "tally_ho_01";
		private const OPEN_ARMORY:String = "fridge_door_open_01";
		private const UNLOCK_ARMORY:String = "unlocked_04";
		
		private var vanBuren:Entity;
		private var winston:Entity;
		private var costume:Entity;
		private var nightVision:Entity;
		private var glint:Entity;
		private var canIPass:Entity;
		
		private var randomGlint:TimedEvent;
		
		private var lightEffect:ScreenEffects;
		
		private var range:AudioRange;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			if(shellApi.profileManager.active.look.gender == 1)
				shellApi.triggerEvent("boy", true);
			else
				shellApi.triggerEvent("girl", true);
			
			survival = events as Survival4Events;
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			addSystem(new HitTestSystem());
			addSystem(new ThresholdSystem());
			
			range = new AudioRange(1000, 0, 1, Quad.easeIn);
			
			setUpElephantTrunk();
			setUpNPCs();
			setUpClicks();
			setUpHeads();
			setUpStatue();
			setUpSpear();
			setUpArmory();
			setUpNewsPaper();
			manageTour();
			setUpSoftHits();
			//setUpDarkness();
		}
		
		private function setUpDarkness():void
		{
			lightEffect = new ScreenEffects(groupContainer, shellApi.viewportWidth, shellApi.viewportHeight, ROOM_DARKNESS);
			lightEffect.box.mouseEnabled = false;
			lightEffect.box.name = 'lightLayer';
			// was in the center of the screen so moved to be in top left corner
			lightEffect.box.x -= lightEffect.box.width / 2;
			lightEffect.box.y -= lightEffect.box.height / 2;
			// positioned above any of the layers of the scene but below the ui
			this.groupContainer.setChildIndex(lightEffect.box, this.groupContainer.getChildIndex(getEntityById("uiLayer").get(Display).displayObject));
		}
		
		private function setUpSoftHits():void
		{
			var softHits:Entity = getEntityById("softFloor");
			softHits.add(new HitTest(puff));
		}
		
		private function puff(entity:Entity, hitId:String):void
		{
			var hit:Entity = getEntityById(hitId);
			var spatial:Spatial = hit.get(Spatial);
			var poof:PoofBlast = new PoofBlast();
			poof.init(10, 5, 0xA49B94);
			EmitterCreator.create(this, _hitContainer, poof, spatial.x, spatial.y + spatial.height / 2);
			trace("poof");
		}
		
		private function setUpNewsPaper():void
		{
			var clip:MovieClip = _hitContainer["newsPaper"];
			var sprite:Sprite = BitmapUtils.createBitmapSprite(clip,.1);
			var newsPaper:Entity = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
			newsPaper.add(new Id(clip.name)).add(new SceneInteraction());
			InteractionCreator.addToEntity(newsPaper, ["click"], sprite);
			SceneInteraction(newsPaper.get(SceneInteraction)).reached.add(lookAtNewspaper);
			ToolTipCreator.addToEntity(newsPaper);
			Display(newsPaper.get(Display)).alpha = 0;
			Display(newsPaper.get(Display)).moveToBack();
			_hitContainer.removeChild(clip);
		}
		
		private function lookAtNewspaper(...args):void
		{
			addChildGroup(new OneShotPopup(overlayContainer, "newspaper.swf", "scenes/survival4/trophyRoom/newspaperPopup/",false));
		}
		
		private function setUpClicks():void
		{
			for each (var click:DisplayObjectContainer in _hitContainer)
			{
				if(click.name.indexOf("Click") != -1)
				{
					var sprite:Sprite = BitmapUtils.createBitmapSprite(click,.1);
					var animal:String = click.name.substr(0, click.name.length - 5);
					var entity:Entity = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
					entity.add(new Id(click.name)).add(new Audio()).add(range);
					var interaction:Interaction = InteractionCreator.addToEntity(entity, ["click"], sprite);
					interaction.click.add(Command.create(clickAnimal, animal));
					Display(entity.get(Display)).alpha = 0;
					ToolTipCreator.addToEntity(entity);
					_hitContainer.removeChild(click);
				}
			}
		}
		
		private function clickAnimal(entity:Entity, animal:String):void
		{
			if(animal == "tally_ho")
				Dialog(entity.get(Dialog)).sayCurrent();
			var audio:Audio = entity.get(Audio);
			if(!audio.isPlaying(SoundManager.EFFECTS_PATH + animal + "_01" + MP3))
				audio.play(SoundManager.EFFECTS_PATH + animal + "_01" + MP3);
		}
		
		private function setUpArmory():void
		{
			var clip:MovieClip = _hitContainer["armory"];
			var door:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			
			var costumeDisplay:DisplayObjectContainer = EntityUtils.getDisplayObject(costume);
			
			DisplayUtils.moveToOverUnder(costumeDisplay, clip, false);
			
			nightVision = getEntityById("nightVision");
			if(nightVision != null)
			{
				var nightVisionDisplay:DisplayObjectContainer = EntityUtils.getDisplayObject(nightVision);
				
				DisplayUtils.moveToOverUnder(nightVisionDisplay, clip, false);
			}
			
			BitmapTimelineCreator.convertToBitmapTimeline(door,clip);
			var time:Timeline = door.get(Timeline);
			
			if(shellApi.checkEvent(survival.UNLOCKED_ARMORY))
			{
				time.gotoAndStop("open");
				this.addCostumizingToOutfit();
				/*costume.add(new SceneInteraction());
				InteractionCreator.addToEntity(costume, [InteractionCreator.CLICK],costumeDisplay);
				SceneInteraction(costume.get(SceneInteraction)).reached.add(costumize);*/
			}
			else
			{
				Character(costume.get(Character)).costumizable = false;
				door.add(new Id("armory"));
				door.add(new SceneInteraction());
				InteractionCreator.addToEntity(door, ["click"], EntityUtils.getDisplayObject(door));
				var interaction:SceneInteraction = door.get(SceneInteraction);
				interaction.reached.add(locked);
				interaction.validCharStates = new Vector.<String>();
				interaction.validCharStates.push(CharacterState.STAND);
				ToolTipCreator.addToEntity(door);
				if(nightVision != null)// avoiding testing breaks
					nightVision.remove(Item);
			}
		}
		
		private function addCostumizingToOutfit():void
		{
			var characterGroup:CharacterGroup = this.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			characterGroup.configureCostumizerMannequin(costume);
			
			Character(costume.get(Character)).costumizable = true;
		}
		
		private function costumize(player:Entity, dummy:Entity):void
		{
			var dummyLook:LookData = SkinUtils.getLook( dummy, true );
			var costumizer:CostumizerPop = new CostumizerPop(overlayContainer, dummyLook);
			this.addChildGroup(costumizer);
		}
		
		private function locked(player:Entity, door:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("locked");
		}
		
		private function setUpNPCs():void
		{
			vanBuren = getEntityById("van buren");
			winston = getEntityById("winston");
			costume = getEntityById("costume");
			
			var dialog:Dialog = vanBuren.get(Dialog);
			dialog.start.add(lockPlayer);
			
			for(var i:int = 1; i <= 3; i++)
			{
				if(shellApi.checkEvent(survival.TOUR_COMPLETE+i))
				{
					if( i == 3)
					{
						removeEntity(winston);
						winston = null;
						dialog.complete.add(returnControls);
					}
					else
					{
						if(i == 2)
						{
							Spatial(winston.get(Spatial)).y = 925;
							Dialog(winston.get(Dialog)).setCurrentById("charmed2");
						}
						Spatial(vanBuren.get(Spatial)).x = tourPositions[i];
					}
				}
			}
			
			if(shellApi.checkEvent(survival.ATE_MEAT))
			{
				removeEntity(vanBuren);
				vanBuren = null;
			}
			else
			{
				var threshold:Threshold = new Threshold("y", "<");
				threshold.threshold = 700;
				threshold.entered.add(getDownFromThere);
				player.add(threshold);
				
				var clip:Sprite = new Sprite();
				canIPass = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				threshold = new Threshold("x", ">");
				threshold.target = vanBuren.get(Spatial);
				threshold.entered.add(youShallNotPass);
				canIPass.add(threshold).add(new FollowTarget(player.get(Spatial)));
			}
			
			var sprite:Sprite = BitmapUtils.createBitmapSprite(_hitContainer["stand"]);
			_hitContainer.addChild(sprite);
			_hitContainer.removeChild(_hitContainer["stand"]);
			DisplayUtils.moveToOverUnder(sprite, _hitContainer["hyena"]);
			
			Display(player.get(Display)).moveToFront();
		}
		
		private function youShallNotPass():void
		{
			var phrase:String = "you shall not pass";
			if(tourComplete)
				phrase = "dont tarry";
			continueDialog(phrase, getBack, true);
		}
		
		private function getBack(...args):void
		{
			var spatial:Spatial = vanBuren.get(Spatial);
			CharUtils.moveToTarget(player, spatial.x - 100, 925, true, returnControls);
		}
		
		private function lockPlayer(...args):void
		{
			SceneUtil.lockInput(this);
		}
		
		private function getDownFromThere():void
		{
			continueDialog("no tomfoolery", getDown, true);
		}
		
		private function getDown(...args):void
		{
			var spatial:Spatial = player.get(Spatial);
			var vanBurenSpatial:Spatial = vanBuren.get(Spatial);
			var posX:Number = spatial.x;
			if(posX > vanBurenSpatial.x)
				posX = vanBurenSpatial.x -100;
			var destination:Destination = CharUtils.moveToTarget(player, posX, 925, true, returnControls);
			destination.ignorePlatformTarget = true;
		}
		
		private function setUpSpear():void
		{
			var clip:MovieClip = _hitContainer["spear"];
			var sparkle:MovieClip = _hitContainer["spearSparkle"];
			if(shellApi.checkHasItem(survival.SPEAR))
			{
				_hitContainer.removeChild(clip);
				_hitContainer.removeChild(sparkle);
			}
			else
			{
				if(shellApi.checkEvent(survival.ATE_MEAT))
				{
					BitmapUtils.convertContainer(clip);
					var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
					entity.add(new Id(clip.name)).add(new SceneInteraction());
					entity.add(new Item());
					var interaction:SceneInteraction = entity.get(SceneInteraction);
					InteractionCreator.addToEntity(entity, ["click"], clip);
					interaction.reached.add(pickUpSpear);
					ToolTipCreator.addToEntity(entity);
					
					glint = TimelineUtils.convertClip(sparkle, this);
					randomizeGlint(glint);
				}
				else
				{
					_hitContainer.removeChild(sparkle);
				}
			}
		}
		
		private function pickUpSpear(player:Entity, spear:Entity):void
		{
			if(shellApi.checkEvent(survival.ATE_MEAT))
			{
				shellApi.getItem(survival.SPEAR,null, true);
				removeEntity(spear);
				removeEntity(glint);
				randomGlint.stop();
			}
			else
				Dialog(player.get(Dialog)).sayById("not now");
		}
		
		private function randomizeGlint(glint:Entity):void
		{
			randomGlint = SceneUtil.addTimedEvent(this, new TimedEvent(Math.random() * 3 + 2, 1, Command.create(playGlint, glint)));
		}
		
		private function playGlint(glint:Entity):void
		{
			glint.get(Timeline).gotoAndPlay("glint");
			randomizeGlint(glint);
		}
		
		private function setUpStatue():void
		{
			var clip:MovieClip = _hitContainer["statue"];
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			entity.add(new Id(clip.name));
			BitmapTimelineCreator.convertToBitmapTimeline(entity, clip);
			
			if(shellApi.checkEvent(survival.STATUE_FELL))
			{
				Timeline(entity.get(Timeline)).gotoAndStop(1);
				_hitContainer.removeChild(_hitContainer["dustCloud"]);
				clip.mouseEnabled = false;
				getEntityById("statueHit").remove(Platform);
			}
			else
			{
				var interaction:Interaction = InteractionCreator.addToEntity(entity, ["click"], EntityUtils.getDisplayObject(entity));
				interaction.click.add(Command.create(clickAnimal, "tally_ho"));
				ToolTipCreator.addToEntity(entity);
				entity.add(new Audio()).add(range);
				
				getEntityById("statueBrokeHit").remove(Platform);
				CharUtils.assignDialog(entity, this, "statue",false,0,.5);
				
				clip = _hitContainer["dustCloud"];
				if(survival.ATE_MEAT && !PlatformUtils.isMobileOS)
				{
					var dustCloud:Entity = BitmapTimelineCreator.convertToBitmapTimeline(null,clip);
					Timeline(dustCloud.get(Timeline)).handleLabel("ending", Command.create(removeEntity, dustCloud, true));
					dustCloud.add(new Id("dustCloud"));
				}
				else
					_hitContainer.removeChild(clip);
				
				var voiceRecording:Entity = getEntityById("voiceRecording");
				
				if(voiceRecording != null)// avoiding errors while testing
				{
					Display(voiceRecording.get(Display)).visible = false;
					voiceRecording.remove(Item);
					ToolTipCreator.removeFromEntity(voiceRecording);
				}
			}
		}
		
		private function setUpHeads():void
		{
			for(var i:int = 0; i < heads.length; i++)
			{
				var clipName:String = heads[i];
				var clip:DisplayObjectContainer = _hitContainer[clipName];
				if(PlatformUtils.isMobileOS)
				{
					// Matt Caulkins : create new displayObjectContainer when removing the vector heads
					var newClip:DisplayObjectContainer = BitmapUtils.createBitmapSprite(clip,1);
					_hitContainer.removeChild(clip);
				}
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				entity.add(new Id(clipName));
				Display(entity.get(Display)).moveToBack();
				
				if(shellApi.checkEvent(clipName+FELL))
					dropInteraction(entity, clipName,i);
				else
				{
					var interaction:Interaction = InteractionCreator.addToEntity(entity, ["click"], clip);
					interaction.click.add(Command.create(clickAnimal, clipName));
					ToolTipCreator.addToEntity(entity);
					entity.add(new Audio()).add(range);
					
					if(clipName == "hyena")
					{
						getEntityById(clipName+"Hit").add(new HitTest(Command.create(headFalls, entity, i)));
					}
					if(clipName == "alligator")
					{
						if(shellApi.checkEvent(survival.TOUR_COMPLETE+2))
						{
							Spatial(entity.get(Spatial)).rotation = -7.5;
							setUpGatorHit(entity);
						}
					}
				}
			}
		}
		
		private function headFalls(entity:Entity, hitId:String, display:Entity, interactionNumber:int):void
		{
			var displayName:String = Id(display.get(Id)).id;
			var groupStart:int = interactionNumber * 3;
			TweenUtils.entityTo(display, Spatial, .75, {x:fallPositions[groupStart], y:fallPositions[groupStart+1], rotation:fallPositions[groupStart+2], ease:Quad.easeIn, onComplete:Command.create(headFell, interactionNumber) });
			shellApi.completeEvent(displayName + FELL);
			removeEntity(entity);
			display.remove(Interaction);
			display.remove(Sleep);
			ToolTipCreator.removeFromEntity(display);
			
			clickAnimal(display, displayName);
			
			var spatial:Spatial = player.get(Spatial);
			SceneUtil.setCameraPoint(this, spatial.x, spatial.y);
		}
		
		private function headFell(interactionNumber:int):void
		{
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + headSounds[interactionNumber]+MP3);
			returnControls();
		}
		
		private function dropInteraction(interaction:Entity, interactionId:String, interactionNumber:int):void
		{
			removeEntity(getEntityById(interactionId+"Hit"));
			_hitContainer[interactionId].mouseEnabled = false;
			if(interactionId == "alligator")
			{
				removeEntity(getEntityById("alligator"));
				return;
			}
			var spatial:Spatial = interaction.get(Spatial);
			var groupStart:int = interactionNumber * 3;
			
			spatial.x = fallPositions[groupStart];
			spatial.y = fallPositions[groupStart + 1];
			spatial.rotation = fallPositions[groupStart + 2];
		}
		
		private function setUpGatorHit(alligator:Entity):void
		{
			getEntityById(Id(alligator.get(Id)).id+"Hit")
			.add(new HitTest(Command.create(headFalls, alligator, 1)));
			
			var threshold:Threshold = new Threshold("y", ">");
			threshold.threshold = 750;
			threshold.entered.add(breakStatue);
			alligator.add(threshold);
		}
		
		private function breakStatue():void
		{
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + STATUE_BREAKS +MP3);
			
			shellApi.completeEvent(survival.STATUE_FELL);
			removeEntity(getEntityById("alligator"));
			removeEntity(getEntityById("statueHit"));
			
			returnControls();
			
			var statue:Entity = getEntityById("statue");
			statue.remove(Interaction);
			ToolTipCreator.removeFromEntity(statue);
			Timeline(statue.get(Timeline)).gotoAndStop(1);
			EntityUtils.getDisplayObject(statue).mouseEnabled = false;
			getEntityById("statueBrokeHit").add(new Platform());
			
			var voiceRecording:Entity = getEntityById("voiceRecording");
			Display(voiceRecording.get(Display)).visible = true;
			voiceRecording.add(new Item());
			ToolTipCreator.addToEntity(voiceRecording);
			
			var dust:Entity = getEntityById("dustCloud");
			
			if(dust != null)
				Timeline(dust.get(Timeline)).play();
		}
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event.indexOf(survival.TOUR_COMPLETE) == 0)
			{
				manageTour();
				
				if(event == survival.TOUR_COMPLETE + 1 && tourPosition == 1)
					walkToNextPosition();
				
				if(event == survival.TOUR_COMPLETE + 2 && tourPosition == 2)
					tallyHo();
				
				if(event == survival.TOUR_COMPLETE + 3 && tourPosition == 3)
				{
					exitTrophyRoom(winston);
					continueDialog("meet me", Command.create(setLastDialog, vanBuren));
				}
			}
			
			if(event.indexOf("key") != -1)
			{
				useKey(event);
			}
			if(event.indexOf(survival.TROPHY_LIT) == 0)
			{
				lightPosition = int(event.charAt(11)) - 1;
				walkToNextPosition();
			}
			
			if(event == survival.MEET_WINSTON)
			{
				meetWinston();
			}
			
			if( event == _events.USE_EMPTY_PITCHER || event == _events.USE_FULL_PITCHER || event == _events.USE_SPEAR || event == _events.USE_TAINTED_MEAT)
			{
				player.get(Dialog).sayById("no_use");
			}
			if(event == "gotItem_spear")
			{
				//Remove sparkle
				var clip:DisplayObject = this._hitContainer.getChildByName("spearSparkle");
				if(clip)
				{
					clip.parent.removeChild(clip);
				}
			}
		}
		
		private function meetWinston():void
		{
			var spatial:Spatial = winston.get(Spatial);
			var destination:Destination = CharUtils.moveToTarget(winston, spatial.x, 925,false, droll, new Point(25,25));
			destination.ignorePlatformTarget = true;
			var fsm:FSMControl = winston.get(FSMControl);
			fsm.active = true;
			fsm.setState(CharacterState.STAND);
		}
		
		private function droll(...args):void
		{
			Dialog(winston.get(Dialog)).sayById("droll");
		}
		
		private function useKey(keyType:String):void
		{
			var armory:Entity = getEntityById("armory");
			if(closeToEntity(armory) && !shellApi.checkEvent(survival.UNLOCKED_ARMORY))
			{
				if(keyType == survival.USE_ARMORY_KEY)
				{
					var interaction:SceneInteraction = armory.get(SceneInteraction);
					interaction.reached.removeAll();
					interaction.reached.add(unlockArmory);
					
					interaction.activated = true;
				}
				else
					Dialog(player.get(Dialog)).sayById("wrong_key");
			}
			else
				Dialog(player.get(Dialog)).sayById("no_use");
		}
		
		private function unlockArmory(player:Entity, armory:Entity):void
		{
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + UNLOCK_ARMORY+MP3);
			SceneUtil.lockInput(this);
			CharUtils.setAnim(player, PourPitcher);
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "dd_key",false );
			Timeline(player.get(Timeline)).handleLabel("ending", Command.create(openArmory, armory));
		}
		
		private function openArmory(armory:Entity):void
		{
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + OPEN_ARMORY+MP3);
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM,false );
			shellApi.completeEvent(survival.UNLOCKED_ARMORY);
			Timeline(armory.get(Timeline)).gotoAndStop("open");
			ToolTipCreator.removeFromEntity(armory);
			armory.remove(SceneInteraction);
			nightVision.add(new Item());
			
			this.addCostumizingToOutfit();
			
			SceneUtil.lockInput(this, false);
		}
		
		private var distanceCheck:Number = 250;
		private function closeToEntity(entity:Entity):Boolean
		{
			var entitySpatial:Spatial = entity.get(Spatial);
			var playerSpatial:Spatial = player.get(Spatial);
			var entityPos:Point = new Point(entitySpatial.x, entitySpatial.y);
			var playerPos:Point = new Point(playerSpatial.x, playerSpatial.y);
			if(Point.distance(entityPos, playerPos) < distanceCheck)
				return true;
			return false;
		}
		
		private function tallyHo():void
		{
			CharUtils.setDirection(vanBuren, false);
			CharUtils.setAnim(vanBuren, Knock);
			Timeline(vanBuren.get(Timeline)).handleLabel("ending", sayTallyHo);
		}
		
		private function sayTallyHo():void
		{
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + TALLY_HO+MP3);
			var dialog:Dialog = getEntityById("statue").get(Dialog);
			dialog.sayCurrent();
			dialog.complete.addOnce(tiltAlligator);
		}
		
		private function tiltAlligator(...args):void
		{
			var alligator:Entity = getEntityById("alligator");
			setUpGatorHit(alligator);
			
			SceneUtil.setCameraTarget(this, alligator);
			TweenUtils.entityTo(alligator, Spatial, .5, {rotation:-7.5});
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(continueDialog, "taxidermist", lockPlayer())));
		}
		
		private function knockOverSpear():void
		{
			var spear:Entity = getEntityById("spear");
			spear.add(new SceneInteraction());
			InteractionCreator.addToEntity(spear, ["click"], EntityUtils.getDisplayObject(spear));
			SceneInteraction(spear.get(SceneInteraction)).reached.add(pickUpSpear);
			ToolTipCreator.addToEntity(spear);
			
			shellApi.completeEvent(survival.SPEAR_FELL);
			CharUtils.setDirection(vanBuren, true);
			TweenUtils.entityTo(spear, Spatial, .5, {x:fallPositions[0], y:fallPositions[1], rotation:fallPositions[2], ease:Quad.easeIn, onComplete:Command.create(continueDialog, "oh well")}); 
		}
		
		private function continueDialog(dialogId:String, method:Function = null, lockInPut:Boolean = false):void
		{
			if(method == null)
				method = walkToNextPosition;
			
			if(vanBuren)
			{
				SceneUtil.setCameraTarget(this, vanBuren);
				SceneUtil.lockInput(this, lockInPut);
				CharUtils.setDirection(vanBuren, false);
				var dialog:Dialog = vanBuren.get(Dialog);
				dialog.sayById(dialogId);
				dialog.complete.addOnce(method);
			}
		}
		
		private function walkToNextPosition(...args):void
		{
			if(vanBuren == null)
				return;
			
			var position:Number;
			if(showingTrophies)
			{
				position = trophyPositions[lightPosition];
				CharUtils.moveToTarget(vanBuren, position + TROPHY_TOUR_OFFSET, 950, true, null, new Point(25, 100));
				CharUtils.moveToTarget(player, position + TROPHY_TOUR_OFFSET * 2, 950, true, null, new Point(25, 100));
				CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 300;
			}
			else
			{
				returnControls();
				position = tourPositions[tourPosition];
				CharUtils.moveToTarget(vanBuren, position, 950, true, setDialog, new Point(25, 100));
			}
			
			CharacterMotionControl(vanBuren.get(CharacterMotionControl)).maxVelocityX = 300;
		}
		
		private function setLastDialog(dialog:DialogData, entity:Entity):void
		{
			returnControls();
			Dialog(vanBuren.get(Dialog)).complete.add(returnControls);
			setDialog(entity);
		}
		
		private function exitTrophyRoom(entity:Entity):void
		{
			var spatial:Spatial = getEntityById("door1").get(Spatial);
			if(entity)
			{
				CharUtils.moveToTarget(entity, spatial.x, spatial.y, false, exit,new Point(100,100));
				CharacterMotionControl(entity.get(CharacterMotionControl)).maxVelocityX = 300;
				entity.remove(Sleep);
			}
		}
		
		private function exit(entity:Entity):void
		{
			removeEntity(entity,true);
		}
		
		private function setDialog(entity:Entity):void
		{
			Dialog(vanBuren.get(Dialog)).setCurrentById(tourDialogIds[tourPosition]);
		}
		
		private function manageTour():void
		{			
			var currentDialogId:String = tourDialogIds[0];
			tourPosition = 0;
			showingTrophies = false
			
			for(var i:int = 1; i <= 3; i ++)
			{
				if(shellApi.checkEvent(survival.TOUR_COMPLETE+i))
				{
					currentDialogId = tourDialogIds[i];
					tourPosition = i;
				}
			}
			
			if(tourPosition == 0)
			{
				showingTrophies = true;
				Timeline(winston.get(Timeline)).stop();
				SkinUtils.setEyeStates(winston, EyeSystem.CASUAL_STILL);
			}
			
			if(tourPosition == 1)
			{
				lightPosition = 3;
				//lightTrophy();
				walkToNextPosition();
				CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 800;
				Dialog(winston.get(Dialog)).setCurrentById("charmed2");
			}
			
			if(tourPosition == 3)
				tourComplete = true;
			
			if(vanBuren != null)
				Dialog(vanBuren.get(Dialog)).setCurrentById(currentDialogId);
		}
		
		private function setUpElephantTrunk():void
		{
			addSystem(new TriggerHitSystem());
			var clip:MovieClip = _hitContainer["elephantTrunk"];
			BitmapUtils.convertContainer(clip);
			var bounceEntity:Entity = getEntityById("bounce");
			var trunk:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(clip, this, trunk, null, false);
			bounceEntity.add(new TriggerHit(trunk.get(Timeline)));
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
			// Matt Caulkins : remove the player lock from CharUtils.moveToTarget
			CharUtils.lockControls( player, false, false );
			var spatial:Spatial = player.get(Spatial);
			MotionTarget(player.get(MotionTarget)).targetDeltaY = spatial.y;
		}
	}
}