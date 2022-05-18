package game.scenes.reality2.mainStreet
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.HitTest;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.data.scene.hit.MovingHitData;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.hub.town.Town;
	import game.scenes.map.map.Map;
	import game.scenes.reality2.Reality2Events;
	import game.scenes.reality2.shared.RealityScene;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TweenEntityAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.hit.HitTestSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class MainStreet extends PlatformerGameScene
	{
		public var reality2:Reality2Events;
		private var _charGroup:CharacterGroup;
		
		private var host:Entity;
		private var cameraGuy1:Entity;
		private var cameraGuy2:Entity;
		private var helicopter:Entity;
		private var playerParent:DisplayObjectContainer;
		private var helicopterPlat1:Entity;
		private var helicopterPlat2:Entity;
		
		private var explodingCameraman:Entity;
		private var explodingCameramanInteraction:Interaction;
		private var bird:Entity;
		private var monkey1:Entity;
		private var monkey1Interaction:Interaction;
		private var giraffe:Entity;
		private var giraffeInteraction:Interaction;
		private var zebra:Entity;
		private var zebraInteraction:Interaction;
		
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/reality2/mainStreet/";
			
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
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			_charGroup = new CharacterGroup();  
			_charGroup.setupGroup(this);
			host = this.getEntityById("probably");
			cameraGuy1 = this.getEntityById("cameraguy1");
			cameraGuy2 = this.getEntityById("cameraguy2");
			Dialog(cameraGuy1.get(Dialog)).faceSpeaker = false;
			Dialog(cameraGuy2.get(Dialog)).faceSpeaker = false;
			Dialog(cameraGuy1.get(Dialog)).setCurrentById("have seen");
			SceneInteraction(cameraGuy2.get(SceneInteraction)).reached.addOnce(onCameraGuy2Down);
			
			// setup helicopter moving platforms
			helicopterPlat1 = super.getEntityById("helicopterPlat1");
			helicopterPlat2 = super.getEntityById("helicopterPlat2");
			Display(helicopterPlat1.get(Display)).alpha = 0;
			Display(helicopterPlat2.get(Display)).alpha = 0;
			MovingHitData(helicopterPlat1.get(MovingHitData)).velocity = 7;
			
			helicopter = EntityUtils.createMovingEntity(this, _hitContainer["helicopter"], _hitContainer);
			// optimize
			//convertContainer(Display(helicopter.get(Display)).displayObject);
			
			//positional helicopter sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "helicopter_loop_01.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			entity.add(audio);
			entity.add(new Spatial(796, 259));
			entity.add(new AudioRange(1300, 0, 1, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
			
			var playerSpatial:Spatial = player.get(Spatial);
			var hostSpatial:Spatial = host.get(Spatial);
			
			var item:Entity = SkinUtils.getSkinPartEntity(cameraGuy1, SkinUtils.ITEM);
			Spatial(item.get(Spatial)).rotation = 20;
			var item2:Entity = SkinUtils.getSkinPartEntity(cameraGuy2, SkinUtils.ITEM);
			Spatial(item2.get(Spatial)).rotation = 20;
			
			var comingFromCommon:Boolean = false;
			if ( super.shellApi.sceneManager.previousScene == "game.scenes.reality2.common::Common")
			{
				comingFromCommon = true;
			}
			
			setupBird();
			setupStaticAnimations();
			setupClickableAnimations();
			
			if(shellApi.checkEvent(reality2.GAMES_STARTED))
			{
				Dialog(host.get(Dialog)).setCurrentById("returnToGame");
			}
			else
			{
				Dialog(host.get(Dialog)).setCurrentById("afterIntro");
			}
			
			// saw the helicopter intro
			if(shellApi.checkEvent(reality2.SAW_INTRO))
			{
				setupHelicopter();
				
				if(!comingFromCommon)
				{
					playerSpatial.x = 800;
					playerSpatial.y = 858;
				}
				
				hostSpatial.x = 938;
				hostSpatial.y = 858;
				// already completed island
				if( shellApi.checkEvent( GameEvent.HAS_ITEM + reality2.MEDAL_REALITY2 ))
				{
					Dialog(host.get(Dialog)).setCurrentById("replay");
				}
				else if(shellApi.checkEvent(reality2.COMPETITION_FINISHED))
				{
					// just finished all competitions
					CharUtils.sayDialog(host,"medallion");
				}
			}
			else
			{
				// first time playing island
				intro();
			}
		}
		
		private function onCameraGuy2Down(...args):void
		{
			Dialog(cameraGuy1.get(Dialog)).sayById("have seen");
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			// load village scene or current game
			if( event == "gotoVillage" )
			{ 
				// handled in village scene				
				RealityScene.getNextContest(shellApi,!shellApi.checkEvent(reality2.COMPETITION_FINISHED));
			}
			else if( event == "getMedallion" )
			{
				// get medallion
				SceneUtil.lockInput(this, false);
				Dialog(host.get(Dialog)).setCurrentById("replay");
				
				if( !shellApi.checkEvent( GameEvent.HAS_ITEM + reality2.MEDAL_REALITY2 ))
				{
					
					shellApi.getItem( reality2.MEDAL_REALITY2, null, true, afterMedal );
				}
				else
				{
					afterMedal();
				}
			}
			else if( event == "returnControl" )
			{
				returnControl();
			}
			else if( event == "setCameramenDialog" )
			{
				SceneInteraction(cameraGuy2.get(SceneInteraction)).reached.remove(onCameraGuy2Down);
				Dialog(cameraGuy1.get(Dialog)).setCurrentById("hah");
				Dialog(cameraGuy2.get(Dialog)).setCurrentById("yeah");
			}
			else if( event == "afterIntro" )
			{
				Dialog(host.get(Dialog)).setCurrentById("afterIntro");
			}
			else if(event == "leave")
			{
				if(shellApi.profileManager.active.isGuest)
				{
					shellApi.loadScene(Town);
				}
				else
				{
					shellApi.loadScene(Map);
				}
			}
		}
		
		private function intro():void
		{
			// tracking
			shellApi.track("LandedOnMainStreet");
			
			SceneUtil.lockInput(this);
			
			playerParent = player.get(Display).displayObject.parent;
			
			MovingHitData(helicopterPlat1.get(MovingHitData)).pause = true;
			MovingHitData(helicopterPlat2.get(MovingHitData)).pause = true;
			
			var hostSpatial:Spatial = host.get(Spatial);
			var playerSpatial:Spatial = player.get(Spatial);
			
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new CallFunctionAction( playerInPlane) );
			actChain.addAction( new TweenEntityAction(helicopter, Spatial, 10, {x: 792, y: 258}));
			actChain.addAction( new CallFunctionAction( exitHelicopter ) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( setupHelicopter ) );
			actChain.addAction( new MoveAction( host, new Point( 938, 820 )));
			actChain.addAction( new TalkAction( host, "welcome" ));
			actChain.execute();			
		}
		
		private function returnControl():void 
		{
			SceneUtil.lockInput(this, false);
		}
		
		private function playerInPlane():void
		{
			characterInPlane(player, helicopter, "player", "right", new Spatial(-5, 15));
			
			CharUtils.setAnim(player, Stand);
			CharUtils.setDirection(player, true);
			
			MotionUtils.zeroMotion(player);
			SceneUtil.setCameraTarget(this, helicopter);
		}
		
		protected function characterInPlane(char:Entity, plane:Entity, name:String, direction:String = "right", offset:Spatial = null, stand:Boolean = true, underPlane:Boolean = true):Entity
		{
			_charGroup.removeFSM(char);
			
			char.add(new Motion()); // turn off falling 
			if(stand) CharUtils.setAnim(char, Stand);
			
			var spatial:Spatial = char.get(Spatial);
			spatial.rotation = 0;
			
			// add spatial offset if necessary
			if(offset)
			{
				spatial.x = offset.x;
				spatial.y = offset.y;
			}
			
			// remove sleep
			Sleep(char.get(Sleep)).sleeping = false;
			Sleep(char.get(Sleep)).ignoreOffscreenSleep = true;
			
			var display:Display = char.get(Display);
			display.setContainer(EntityUtils.getDisplayObject(plane));
			
			return char;
		}
		
		private function exitHelicopter():void
		{
			SceneUtil.setCameraTarget(this, player);
			_charGroup.addFSM(player);
			
			var display:Display = player.get(Display);
			display.setContainer(playerParent);
			
			var spatial:Spatial = player.get(Spatial);
			spatial.x = helicopter.get(Spatial).x;
			spatial.y = helicopter.get(Spatial).y;
			
			shellApi.completeEvent(reality2.SAW_INTRO);
			
		}
		
		private function setupHelicopter():void
		{
			MovingHitData(helicopterPlat1.get(MovingHitData)).pause = false;
			EntityUtils.followTarget( helicopter, helicopterPlat1, 1, new Point(7,-55), false);
			EntityUtils.followTarget( helicopterPlat2, helicopterPlat1, 1, new Point(40,85), false);
			
		}
		
		private function setupClickableAnimations():void
		{
			var animations:Array = ["explodingCameraman", "monkey1", "giraffe", "zebra"];
			for(var i:int = 0; i < animations.length; i++)
			{
				var clip:MovieClip = _hitContainer[animations[i]];
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this);
				var interaction:Interaction = entity.get(Interaction);
				interaction.down.add(onClickDown);
				TimelineUtils.convertAllClips(clip, null, this, true, 30, entity);
			}
		}
		
		private function onClickDown(entity:Entity):void
		{
			entity.get(Timeline).gotoAndPlay("click");
			var id:String = entity.get(Id).id;
			switch (id)
			{
				case "monkey1":
					super.shellApi.triggerEvent("monkey1Sound");
					break;
				case "explodingCameraman":
					super.shellApi.triggerEvent("explodingCameramanSound");
					super.shellApi.triggerEvent("explodingCameramanSound2");
					break;
				case "giraffe":
					super.shellApi.triggerEvent("giraffeSound");
					break;
				case "zebra":
					super.shellApi.triggerEvent("zebraSound");
					break;
			}
		}
		
		private function setupStaticAnimations():void
		{
			var animations:Array = ["monkeys","monkey2","beans","t1","t2","t3","t4","sunAnimation","bannerAnimation","holes"];
			for(var i:int = 0; i < animations.length; i++)
			{
				TimelineUtils.convertAllClips(MovieClip(MovieClip(_hitContainer)[animations[i]]), null, this, true, 30);	
			}
			
		}
		
		private function setupBird():void
		{
			var clip:MovieClip = _hitContainer["bird"];
			if(clip)
			{
				addSystem(new HitTestSystem());
				bird = TimelineUtils.convertClip(clip, this, bird, null, true, 30);
				bird.add(new Id(clip.name));
				var hit:Entity = getEntityById(clip.name+"_hit");
				if(hit)
				{
					hit.add(new HitTest(birdBounce));
				}
			}
		}
		
		private function birdBounce(entity:Entity, id:String):void
		{
			bird.get(Timeline).gotoAndPlay("hit");
			super.shellApi.triggerEvent("birdSound");
		}
		
		private function afterMedal():void
		{
			shellApi.completedIsland(null, null);
			//not currently used. Intended as a place to change dialog etc. for post medal interaction.
		}
	}
}