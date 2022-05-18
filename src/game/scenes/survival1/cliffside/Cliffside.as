package game.scenes.survival1.cliffside
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.hit.Climb;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.particles.emitter.PoofBlast;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.shared.SurvivalScene;
	import game.scenes.survival1.shared.popups.FirePopup;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class Cliffside extends SurvivalScene
	{
		public function Cliffside()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival1/cliffside/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var sur:Survival1Events;
		
		private var fade:ScreenEffects;
		
		// all assets ready
		override public function loaded():void
		{
			shellApi.eventTriggered.add(onEventTriggered);
			
			sur = events as Survival1Events;
			
			setUpPages();
			setUpAxe();
			setUpParachute();
			setUpDeadStump();
			setUpFall();
			setUpBackPack();
			
			super.loaded();
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == sur.RETRIEVED_STRIKER)
			{
				var hole:Entity = getEntityById("snowHole");
				hole.remove(SceneInteraction);
				hole.remove(Interaction);
				ToolTipCreator.removeFromEntity(hole);
			}
		}
		
		private function setUpBackPack():void
		{
			addSystem(new ShakeMotionSystem());
			var clip:MovieClip = _hitContainer["backpack"];
			var backPack:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			backPack.add(new Id("backpack"));
			
			var child:MovieClip = clip["flap"];
			var flap:Entity = EntityUtils.createSpatialEntity(this,child,clip);
			TimelineUtils.convertClip(child, this,flap, backPack, false);
			flap.add(new Id("flap"));
			var time:Timeline = flap.get(Timeline);
			time.handleLabel("ending", Command.create(stopFlapping, time),false);
			
			clip = _hitContainer["snowHole"];
			var snowHole:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			snowHole.add(new Id("snowHole")).add(new SceneInteraction());
			InteractionCreator.addToEntity(snowHole,["click"],clip);
			
			Display(snowHole.get(Display)).visible = false;
			
			if(shellApi.checkEvent(sur.DROPPED_STRIKER))
			{
				Display(snowHole.get(Display)).visible = true;
				if(!shellApi.checkEvent(sur.RETRIEVED_STRIKER))
				{
					ToolTipCreator.addToEntity(snowHole);
					SceneInteraction(snowHole.get(SceneInteraction)).reached.add(pickUpStriker);
				}
			}
			else
			{
				var interaction:Interaction = InteractionCreator.addToEntity(backPack, ["click"], _hitContainer["backpack"]);
				interaction.click.add(interactWithBackPack);
				ToolTipCreator.addToEntity(backPack);
			}
		}
		
	
		
		private function interactWithBackPack(backPack:Entity):void
		{
			shakeBackPack(backPack, 15);
			SceneUtil.lockInput(this);
		}
		
		private function shakeBackPack(backPack:Entity, degrees:int):void
		{
			var spatial:Spatial = backPack.get(Spatial);
			TweenUtils.entityTo(backPack, Spatial, .25, {rotation:spatial.rotation + degrees, onComplete:Command.create(rockBack, backPack, degrees)});
		}
		
		private function rockBack(backPack:Entity, degrees:int):void
		{
			var spatial:Spatial = backPack.get(Spatial);
			TweenUtils.entityTo(backPack, Spatial, .25, {rotation:spatial.rotation - degrees, onComplete:flipFlap});
		}
		
		private function flipFlap():void
		{
			var flap:Entity = getEntityById("flap");
			Timeline(flap.get(Timeline)).gotoAndPlay(0);
			if(shellApi.checkEvent(sur.DROPPED_STRIKER))
			{
				lookBackAtPlayer();
				return;
			}
			shellApi.loadFiles([shellApi.assetPrefix+STRIKER_URL],onStrikerLoaded);
		}
		
		private function stopFlapping(timeline:Timeline):void
		{
			timeline.gotoAndStop(0);
		}
		
		private function onStrikerLoaded():void
		{
			var backpack:Entity = getEntityById("backpack");
			ToolTipCreator.removeFromEntity(backpack);
			backpack.remove(Interaction);
			var backpackSpatial:Spatial = backpack.get(Spatial);
			
			var clip:MovieClip = shellApi.getFile(shellApi.assetPrefix+STRIKER_URL);
			
			clip.x = backpackSpatial.x;
			clip.y = backpackSpatial.y;
			
			var striker:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
			
			var strikerSpatial:Spatial = striker.get(Spatial);
			strikerSpatial.scale = .1;
			
			striker.add(new Id("striker"));
			
			var motion:Motion = striker.get(Motion);
			motion.acceleration.y = MotionUtils.GRAVITY;
			
			SceneUtil.setCameraTarget(this, striker);
			
			var threshold:Threshold = new Threshold("y",">");
			threshold.threshold = 1250;
			threshold.entered.add(strikerFell);
			striker.add(threshold);
		}
		
		private function strikerFell():void
		{
			var hole:Entity = getEntityById("snowHole");
			Display(hole.get(Display)).visible = true;
			ToolTipCreator.addToEntity(hole);
			SceneInteraction(hole.get(SceneInteraction)).reached.add(pickUpStriker);
			removeEntity(getEntityById("striker"));
			
			var holeSpatial:Spatial = hole.get(Spatial);
			
			var poofBlast:PoofBlast = new PoofBlast();
			poofBlast.init(25, 10, 0xF5F4F1, .4, .5);
			EmitterCreator.create(this, _hitContainer, poofBlast, holeSpatial.x, holeSpatial.y);
			
			shellApi.completeEvent(sur.DROPPED_STRIKER);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,lookBackAtPlayer));
		}
		
		private function lookBackAtPlayer():void
		{
			SceneUtil.setCameraTarget(this, player);
			SceneUtil.lockInput(this,false);
		}
		
		private function pickUpStriker(...args):void
		{
			if(shellApi.checkEvent(sur.RETRIEVED_STRIKER))
				return;
			addChildGroup(new FirePopup(overlayContainer, 1,false));
		}
		
		private function setUpFall():void
		{
			var threshold:Threshold = new Threshold("y",">");
			threshold.threshold = 2000;
			threshold.entered.add(playerFell);
			player.add(threshold);
			addSystem(new ThresholdSystem());
		}
		
		private function playerFell():void
		{
			
			fade = new ScreenEffects(overlayContainer, shellApi.camera.viewportWidth, shellApi.camera.viewportHeight);
			fade.fadeToBlack(2, bringUpPopup);
			splash();
		}
		
		private function bringUpPopup():void
		{
			var playerSpatial:Spatial = player.get(Spatial);
			playerSpatial.x = 750;
			playerSpatial.y = 1200;
			
			// if npc follower then restore also
			// RLH: this is broken because follower ids now have numbers after their name
			var followerEntity:Entity = this.getEntityById("popFollower");
			if (followerEntity)
			{
				var followerSpatial:Spatial = followerEntity.get(Spatial);
				// 100 pixels to right
				followerSpatial.x = 850;
				followerSpatial.y = 1200;
			}
			
			SceneUtil.lockInput(this,false);
			//var popup:CliffsideFall = addChildGroup(new CliffsideFall(overlayContainer)) as CliffsideFall;
			//popup.closeClicked.add(returnPlayer);
			var fallPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			fallPopup.updateText("you fell down the cliff! watch your step!", "try again");
			fallPopup.configData("cliffside_fall.swf", "scenes/survival1/cliffside/fallPopup/");
			fallPopup.removed.add(returnPlayer);
			addChildGroup(fallPopup);
		}
		
		private function returnPlayer(group:Group):void
		{
			SceneUtil.lockInput(this);
			
			fade.fadeFromBlack(2);
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,returnControls));
		}
		
		private function returnControls():void
		{
			SceneUtil.lockInput(this,false);
		}
		
		private function setUpDeadStump():void
		{
			var clip:MovieClip = _hitContainer["deadStump"];
			var stump:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			
			if(shellApi.checkEvent(sur.PUSHED_STUMP))
			{
				removeEntity(stump);
				return;
			}
			
			stump.add(new SceneInteraction()).add(new Id("stump"));
			InteractionCreator.addToEntity(stump, ["click"], clip);
			var interaction:SceneInteraction = stump.get(SceneInteraction);
			interaction.offsetX = 150;
			interaction.autoSwitchOffsets = false;
			interaction.minTargetDelta.x = 50;
			interaction.minTargetDelta.y = 100;
			interaction.reached.add(pushStump);
			ToolTipCreator.addToEntity(stump);
		}
		
		private function pushStump(player:Entity, stump:Entity):void
		{
			AudioUtils.play(this, "effects/wood_break_01.mp3",1);
			CharUtils.setDirection(player, false);
			CharUtils.setAnim(player, Push);
			SceneUtil.lockInput(this);
			TweenUtils.entityTo(stump, Spatial, 2, {rotation:-90, ease:Linear.easeOut, onComplete:stumpFalls});
			TweenUtils.entityTo(player, Spatial, 2, {x:325, ease:Linear.easeNone});
		}
		
		private function stumpFalls():void
		{
			CharUtils.setAnim(player, Stand);
			var stump:Entity = getEntityById("stump");
			TweenUtils.entityTo(stump, Spatial, 1, {rotation:-180, x:225, y:2000, ease:Linear.easeOut, onComplete:stumpFell});
		}
		
		private function stumpFell():void
		{
			removeEntity(getEntityById("stump"));
			shellApi.completeEvent(sur.PUSHED_STUMP);
			SceneUtil.lockInput(this, false);
			FSMControl(player.get(FSMControl)).active = true;
			CharUtils.setState(player, CharacterState.STAND);
			HitTheDeck(getEntityById("page01").get(HitTheDeck)).ignoreProjectile = false;
			
			splash();
		}
		
		private function splash():void
		{
			AudioUtils.play(this, "effects/explosion_01.mp3",.5);
		}
		
		private function setUpParachute():void
		{
			addSystem( new ZoneHitSystem(), SystemPriorities.checkCollisions);	
			
			var clip:MovieClip = _hitContainer["parachute"];
			var cord:Entity = EntityUtils.createSpatialEntity(this, clip["climbableCord"],_hitContainer);
			cord.add(new Id("cord"));
			var cordSpatial:Spatial = cord.get(Spatial);
			cordSpatial.x += clip.x;
			cordSpatial.y += clip.y;
			
			MovieClip(clip["climbableCord"]).mouseEnabled = false;
			
			MovieClip(clip["handle"]).mouseEnabled = false;
			
			var handle:Entity = EntityUtils.createSpatialEntity(this, clip["handle"], _hitContainer);
			handle.add(new Id("handle"));
			var handleSpatial:Spatial = handle.get(Spatial);
			handleSpatial.x += clip.x;
			handleSpatial.y += clip.y;
			
			var handleZone:Entity = getEntityById("handleZone");
			
			if(shellApi.checkEvent(sur.PULLED_CORD))
			{
				cordSpatial.scaleY = 6;
				handleSpatial.y = 590;
				cordToRope();
				removeEntity(handleZone,true);
				return;
			}
			
			var zone:Zone = handleZone.get(Zone);
			zone.entered.add(pullCord);
			zone.pointHit = true;
		}
		
		private function pullCord(...args):void
		{
			var cord:Entity = getEntityById("cord");
			var handle:Entity = getEntityById("handle");
			
			var follow:FollowTarget = new FollowTarget(handle.get(Spatial));
			follow.offset = new Point(0, 75);
			player.add(follow);
			Motion(player.get(Motion)).pause = true;
			CharUtils.setAnim(player, Fall);
			
			SceneUtil.lockInput(this);
			
			TweenUtils.entityTo(cord, Spatial, 1, {scaleY:6, onComplete:cordToRope});
			TweenUtils.entityTo(handle, Spatial, 1, {y:590});
		}
		
		private function cordToRope():void
		{
			var cord:Entity = getEntityById("cord");
			cord.add(new Climb());
			shellApi.completeEvent(sur.PULLED_CORD);
			removeEntity(getEntityById("handleZone"));
			
			player.remove(FollowTarget);
			Motion(player.get(Motion)).pause = false;
			FSMControl(player.get(FSMControl)).active = true;
			SceneUtil.lockInput(this, false);
		}
		
		private function setUpAxe():void
		{
			var clip:MovieClip = _hitContainer["axe"];
			var axe:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			TimelineUtils.convertClip(clip,this,axe,null,false);
			
			if(shellApi.checkHasItem(sur.AX_HANDLE))
			{
				Timeline(axe.get(Timeline)).gotoAndStop(1);
				removeEntity(getEntityById("axeHandle"));
				return;
			}
			
			var charGroup:CharacterGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			charGroup.preloadAnimations(new <Class>[Pull, Dizzy]);
			
			axe.add(new SceneInteraction()).add(new Id("axe"));
			InteractionCreator.addToEntity(axe,[InteractionCreator.CLICK],clip);
			
			var interaction:SceneInteraction = axe.get(SceneInteraction);
			interaction.reached.add(grabAxe);
			interaction.offsetY = 100;
			interaction.faceDirection = CharUtils.DIRECTION_RIGHT;
			interaction.minTargetDelta = new Point(15, 100);
			ToolTipCreator.addToEntity(axe);
		}
		
		private function grabAxe(player:Entity, axe:Entity):void
		{
			CharUtils.setAnim(player, Pull);
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,pulledAxe));
			SceneUtil.lockInput(this);
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "wood_break_02.mp3" );
		}
		
		private function pulledAxe():void
		{
			var ax:Entity = getEntityById("axe");
			if(SkinUtils.getSkinPart( player, CharUtils.HAND_FRONT).value == "mitten_front")
			{
				Timeline(ax.get(Timeline)).gotoAndStop(1);
				shellApi.getItem(sur.AX_HANDLE,null, true);
				ax.remove(SceneInteraction);
				ToolTipCreator.removeFromEntity(ax);
				FSMControl(player.get(FSMControl)).active = true;
				SceneUtil.lockInput(this, false);
				removeEntity(getEntityById("axeHandle"));
				
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "wood_break_01.mp3" );
			}
			else
			{
				CharUtils.setAnim(player, Dizzy);
				TweenUtils.entityTo(player, Spatial, .5, {x:player.get(Spatial).x - 50});
				SceneUtil.addTimedEvent(this, new TimedEvent(2,1,fell));
			}
		}
		
		private function fell():void
		{
			FSMControl(player.get(FSMControl)).active = true;
			SceneUtil.lockInput(this, false);
			Dialog(player.get(Dialog)).sayById("cant_grip_it");
		}
		
		private function setUpPages():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var clip:MovieClip = _hitContainer["page0"+i];
				if(clip == null)
					continue;
				var page:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				page.add(new SceneInteraction()).add(new Id(clip.name)).add(new HitTheDeck(player.get(Spatial),75,false));
				InteractionCreator.addToEntity(page,["click"],clip);
				HitTheDeck(page.get(HitTheDeck)).duck.add(grabPage);
				ToolTipCreator.addToEntity(page);
				if(shellApi.checkEvent( GameEvent.GOT_ITEM + sur.HANDBOOK_PAGE_ + i))
					removeEntity(page);
			}
			
			if(!shellApi.checkEvent(sur.PUSHED_STUMP))
				HitTheDeck(getEntityById("page01").get(HitTheDeck)).ignoreProjectile = true;
		}
		
		private function grabPage(page:Entity):void
		{
			var pageNumber:int = int(Id(page.get(Id)).id.substr(4));
			
			if(!shellApi.checkEvent(sur.PUSHED_STUMP) && pageNumber == 1)
			{
				Dialog(player.get(Dialog)).sayById("dont_wrip_it");
				return;
			}
			collectPage(page,pageNumber,sur.HANDBOOK_PAGE_ + pageNumber );
		}
		
		private function collectPage(page:Entity, pageNumber:int, pageType:String):void
		{
			var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID, this) as ItemGroup;
			
			if( !shellApi.checkHasItem( sur.HANDBOOK_PAGES ))
			{
				shellApi.getItem( sur.HANDBOOK_PAGES, null, false );
			}
			
			removeEntity(page);
//			shellApi.completeEvent( sur.HAS_PAGE_ + pageNumber );
			shellApi.completeEvent( GameEvent.GOT_ITEM + sur.HANDBOOK_PAGE_ + pageNumber );
			itemGroup.showAndGetItem(pageType);
			shellApi.removeItem(pageType);
		}
		
		private const STRIKER_URL:String = "items/survival1/striker.swf";
	}
}