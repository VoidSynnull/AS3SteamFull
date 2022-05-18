package game.scene.template.ads
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.ColorSet;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Zone;
	import game.components.motion.WaveMotion;
	import game.components.render.Line;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.WaveMotionData;
	import game.data.ads.AdData;
	import game.data.sound.SoundModifier;
	import game.particles.FlameCreator;
	import game.scene.template.ActionsGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.con1.roofRace.NavigationSmart.SmartNavUtils;
	import game.scenes.con1.roofRace.Timer.TimerSystem;
	import game.scenes.custom.AdChoosePopup;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.survival1.cave.particles.CaveDrip;
	import game.scenes.survival1.cave.particles.CaveSplash;
	import game.systems.actionChain.ActionChain;
	import game.systems.entity.character.states.ClimbState;
	import game.systems.entity.character.states.FallState;
	import game.systems.entity.character.states.LandState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.systems.entity.character.states.touch.SkidState;
	import game.systems.entity.character.states.touch.StandState;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class RaceToTheTopGame extends AdGameTemplate
	{
		public function RaceToTheTopGame(container:DisplayObjectContainer=null)
		{
			this.id = "RaceToTheTopGame";
		}
		
		override public function destroy():void
		{
			var i:int = 1;
			var entity:Entity = _scene.getEntityById("drip"+i);
			while(entity)
			{
				CaveDrip(Emitter(entity.get(Emitter)).emitter).deadParticle.removeAll();
				++i;
				entity = _scene.getEntityById("drip"+i);
			}
			path = null;
			npc = null;
			finish = null;
			finishLine.entered.removeAll();
			finishLine = null;
			actions = null;
			flameCreator = null;
			super.destroy();
		}
		
		// all assets ready
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void
		{
			super.setupGame(scene, xml, hitContainer);
			
			parseGameXML(xml);
			
			setUpCountDown();
			
			_scene.addSystem(new HitTheDeckSystem());
			_scene.addSystem(new TimerSystem());
			
			actions = _scene.getGroupById(ActionsGroup.GROUP_ID+RACE_ACTIONS) as ActionsGroup;
			
			setUpNpc();
			
			flameCreator = new FlameCreator();
			var template:MovieClip = _hitContainer["fire1"];
			if(template)
			{
				flameCreator.setup(_scene, template, null, setUpScene);
			}
			else
				setUpScene();
		}
		
		private function setUpScene():void
		{
			var entity:Entity;
			
			for each (var clip:MovieClip in _hitContainer)
			{
				if(clip.totalFrames >1)
				{
					entity = setUpTimeline(clip);
					if(clip.name.indexOf("popup") >= 0)
					{
						setUpPopUpAnimations(entity);
					}
					if(clip.name.indexOf("flag") >= 0)
					{
						var range:AudioRange = new AudioRange(1500, 0, 2, Quad.easeOut);
						entity.add(new Audio()).add(range);
						Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "flag_flapping_01.mp3", true, SoundModifier.POSITION);
					}
				}
				else
				{
					if(clip.name.indexOf("fly")>=0)
					{
						setUpFly(clip);
					}
					if(clip.name.indexOf("drip")>=0)
					{
						setUpDrips(clip);
					}
					if(clip.name.indexOf(ZONE) >= 0)
					{
						if(clip.name == FINISH_ZONE)
							setUpFinishLine();
						else
							setUpZone(clip.name);
					}
					if(clip.name.indexOf("fire") >=0)
					{
						flameCreator.createFlame(_scene, clip);
					}
				}
			}
			if(_choose)
			{
				if(_looks != null)
				{
					var selectionPopup:AdChoosePopup = _scene.loadChoosePopup() as AdChoosePopup;
					selectionPopup.ready.addOnce(gameSetUp.dispatch);
					selectionPopup.selectionMade.addOnce(_scene.playerSelection);
				}
			}
			else
			{
				// dispatch doesn't trigger
				gameSetUp.dispatch(this);
				playerSelection();
			}
		}
		
		override protected function playerSelected(...args):void
		{
			if(_lineThickness != 0)
			{
				var partList:Array = [CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK];
				for each (var part:String in partList)
				{
					var npcPart:Entity = CharUtils.getPart( _scene.shellApi.player, part );
					if (npcPart != null)
						npcPart.get(Line).lineWidth = _lineThickness;					
				}
			}
			///*
			if (_noDarken)
			{
				var limbList:Array = [CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.FOOT_FRONT, CharUtils.FOOT_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK, CharUtils.HAND_FRONT, CharUtils.HAND_BACK];
				for each (var limb:String in limbList)
				{
					// get part entity and set darken percent to 0
					var partEnt:Entity = SkinUtils.getSkinPartEntity(_scene.shellApi.player, limb);
					if (partEnt != null)
					{
						var colorSet:ColorSet = partEnt.get(ColorSet);
						colorSet.darkenPercent = 0;
						colorSet.invalidate = true;
					}
				}
			}
			//*/
			// scale avatar if scale
			if (_scaleSize != 0)
				CharUtils.setScale(_scene.shellApi.player, _scaleSize * 0.36);
			performAction("startNpc");
		}
		
		private function setUpZone(name:String):void
		{
			var entity:Entity = _scene.getEntityById(name);
			if(actions)
			{
				var zone:Zone = entity.get(Zone);
				zone.entered.add(enterZone);
			}
		}
		
		private function enterZone(zoneId:String, entityId:String):void
		{
			var index:int = zoneId.indexOf(ZONE);
			var actionName:String = zoneId.substr(0, index);
			performAction(actionName);
		}
		
		private function setUpTimeline(clip:MovieClip):Entity
		{
			if(clip == null || clip.name == "countDown")
				return null;
			if(PlatformUtils.isMobileOS)
			{
				convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			}
			var entity:Entity= EntityUtils.createSpatialEntity(_scene, clip, _hitContainer);
			TimelineUtils.convertClip(clip, _scene, entity);
			entity.add(new Id(clip.name));
			return entity;
		}
		
		private function setUpPopUpAnimations(entity:Entity):void
		{
			var look:HitTheDeck = new HitTheDeck(_scene.shellApi.player.get(Spatial), 300,false);
			look.duck.add(lookAtPlayer);
			entity.add(look);
		}
		
		private function lookAtPlayer(popup:Entity):void
		{
			Timeline(popup.get(Timeline)).play();
			_scene.shellApi.triggerEvent(popup.get(Id).id);
		}
		
		private static var drips:int = 1;
		
		private function setUpDrips(clip:MovieClip):void
		{
			var range:AudioRange = new AudioRange(1000, 0, 1, Quad.easeIn);
			if(clip)
			{
				var zone:Rectangle = clip.getBounds(_hitContainer);
				var rate:Number = Math.random() * .1 + .1;
				var particle:CaveDrip = new CaveDrip(zone, rate, drips);
				particle.deadParticle.add(playDripAudio);
				var entity:Entity = EmitterCreator.create(_scene, _hitContainer, particle,zone.x, zone.y, null, "drip"+drips);
				
				var splash:CaveSplash = new CaveSplash( new Point(zone.x, zone.bottom) );
				entity = EmitterCreator.create(_scene, _hitContainer, splash,0,0, null, "splash"+drips, null, false);
				entity.add(new Audio()).add(range);
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = zone.x;
				spatial.y = zone.bottom;
				_hitContainer.removeChild(clip);
				++drips;
			}
		}		
		
		private function playDripAudio(caveDrip:CaveDrip):void
		{
			var entity:Entity = _scene.getEntityById("splash" + caveDrip.index);
			
			var emitter:Emitter = entity.get(Emitter);
			emitter.start = true;
			emitter.emitter.start();
			
			Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "drip_0" + Utils.randInRange(1, 3) + ".mp3", false,SoundModifier.POSITION);
		}
		
		private function setUpFly(basePosition:MovieClip):void
		{
			if( basePosition)
			{
				for(var i:int = 1; i <= 4; i++)
				{
					var clip:MovieClip = new MovieClip();
					clip.graphics.beginFill(0,1);
					clip.graphics.drawCircle(0,0,2);
					clip.graphics.endFill();
					
					var fly:Entity = EntityUtils.createSpatialEntity(_scene, BitmapUtils.createBitmapSprite(clip), _hitContainer);
					
					var flyPos:Spatial = fly.get(Spatial);
					flyPos.x = basePosition.x + Math.random() * basePosition.width;
					flyPos.y = basePosition.y + Math.random() * basePosition.height;
					
					fly.add(new SpatialAddition());
					fly.add(new WaveMotion());
					fly.add(new OriginPoint(flyPos.x, flyPos.y));
					fly.add(new Tween());
					
					moveFly(fly);
				}
				_hitContainer.removeChild(basePosition);
			}
		}
		
		private function moveFly(fly:Entity):void
		{
			var wave:WaveMotion = fly.get(WaveMotion);
			wave.data.length = 0;
			wave.data.push(new WaveMotionData("x", Math.random() * 10, Math.random() / 10));
			wave.data.push(new WaveMotionData("y", Math.random() * 10, Math.random() / 10));
			
			var origin:OriginPoint = fly.get(OriginPoint);
			var targetX:Number = (Math.random() - 0.5) * 250 + origin.x;
			var targetY:Number = (Math.random() - 0.5) * 100 + origin.y;
			
			var time:Number = Math.random() * .25 +.5;
			
			var tween:Tween = fly.get(Tween);
			tween.to(fly.get(Spatial), time, {x:targetX, y:targetY, ease:Linear.easeInOut, onComplete:moveFly, onCompleteParams:[fly]});
		}
		
		private function setUpFinishLine():void
		{
			finish = _scene.getEntityById("finishZone");
			finishLine = finish.get(Zone);
			finishLine.entered.add(crossedFinishLine);
			finishLine.pointHit = true;
			finish.remove(Sleep);
		}
		
		private function crossedFinishLine(finishID:String, hitID:String):void
		{
			if(hitID == "player")
			{
				SceneUtil.lockInput(_scene);
				playerFinished = true;
				if(npcFinished)
					youWin(false);
				else if(npc)
				{
					var spatial:Spatial = npc.get(Spatial);
					if(spatial.y > safetyValve.y)
					{
						spatial.x = safetyValve.x;
						spatial.y = safetyValve.y;
						
						var endPoint:Point = path[path.length-1];
						CharUtils.moveToTarget(npc, endPoint.x, endPoint.y);
					}
				}
				else
					youWin(true);
			}
			else
			{
				npcFinished = true;
				if(playerFinished)
					youWin(true);
			}
		}
		
		private function youWin(won:Boolean):void
		{
			finishLine.entered.removeAll();
			
			performAction(won?"win":"lose");
		}
		
		private function setUpNpc():void
		{
			npc = _scene.getEntityById("npc");
			path = SmartNavUtils.createPath(_hitContainer);
			var clip:MovieClip = _hitContainer["safetyValve"];
			if(clip)
			{
				safetyValve = new Point(clip.x, clip.y);
				_hitContainer.removeChild(clip);
			}
			
			if(npc == null)
				return;
			if(!includeNpc)
			{
				removeEntity(npc);
				npc = null;
				return;
			}
			npc.add(new ZoneCollider()).add(new SpecialAbilityControl());
			SmartNavUtils.addSmartNavToChar(PlatformerGameScene(_scene), npc);
			EntityUtils.turnOffSleep(npc);
			
			var states:Vector.<Class> = new <Class>[ ClimbState, FallState, JumpState, LandState, RunState, SkidState, StandState, WalkState ]; 
			CharacterGroup(_scene.getGroupById( CharacterGroup.GROUP_ID )).addFSM( npc, true, states, "stand" );	
			
			SceneInteraction(npc.get(SceneInteraction)).reached.removeAll();
			
			var i:int = 1;;
			var climb:Entity = _scene.getEntityById("climb"+i);
			while(climb)
			{
				climb.remove(Sleep);
				++i;
				climb = _scene.getEntityById("climb"+i);
			}
		}
		
		private function performAction(actionName:String):void
		{
			if(actions)
			{
				var chain:ActionChain = actions.getActionChain(actionName);
				if(chain)
					chain.execute();
			}
		}
		
		public function getReady():void
		{
			if(npc)
			{
				performAction("getReadyNpc");
			}
			else
			{
				performAction("getReady");
			}
		}
		
		private function setUpCountDown():void
		{
			var clip:MovieClip = _hitContainer["countDown"];
			clip.mouseChildren = clip.mouseEnabled = false;
			
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			
			var spatial:Spatial = _scene.shellApi.player.get(Spatial);
			
			clip.x = spatial.x;
			clip.y = spatial.y;
			var scale:Number = _scene.shellApi.viewportScale;
			
			clip.x = Math.max(clip.x - _scene.shellApi.viewportWidth/2/scale, _scene.sceneData.cameraLimits.left);
			clip.y = Math.min(clip.y + _scene.shellApi.viewportWidth/2/scale, _scene.sceneData.cameraLimits.bottom);
			
			clip.x += _scene.shellApi.viewportWidth/2/scale;
			clip.y -= _scene.shellApi.viewportHeight/2/scale;
			clip.gotoAndStop(0);
			countDown = TimelineUtils.convertClip(clip, _scene, null, null, false).get(Timeline);
		}
		
		public function startCountDown():void
		{
			countDown.gotoAndPlay(0);
			countDown.handleLabel("ending", countDownComplete);
			SceneUtil.lockInput(_scene);
		}
		
		private function countDownComplete():void
		{
			countDown.gotoAndStop(0);
			race();
			returnControls();
		}
		
		private function race(...args):void// start npc
		{
			if(npc == null)
				return;
			CharUtils.followPath(npc,path,null,true,false,new Point(50, 100), true);
			CharacterMotionControl(npc.get(CharacterMotionControl)).maxVelocityX = 600;
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(_scene, false);
			SceneUtil.setCameraTarget(_scene, _scene.shellApi.player);
		}
		
		private var path:Vector.<Point>;
		private var npc:Entity;
		
		private var finish:Entity;
		
		private var includeNpc:Boolean = true;
		
		private var playerFinished:Boolean = false;
		private var npcFinished:Boolean = false;
		
		private var finishLine:Zone;
		
		private const START_RACE:String = "start_race";
		private const VIEW_RACE:String = "view_race";
		
		private const RACE_ACTIONS:String = "_race_actions";
		
		private const ZONE:String = "Zone";
		private const FINISH_ZONE:String = "finishZone";// every race should have a finish zone and it performs a specific series of events for ending race
		
		private var actions:ActionsGroup;
		// if you are going to have an npc, you are going to need a safety valve so player doesn't wait forever for the npc to finish
		private var safetyValve:Point;
		
		private var flameCreator:FlameCreator;
		
		private var adData:AdData;
		
		private var countDown:Timeline;
		
		public var _choose:Boolean = false;
		public var _noDarken:Boolean = false;
		public var _lineThickness:Number = 0;
		public var _scaleSize:Number = 0;
	}
}