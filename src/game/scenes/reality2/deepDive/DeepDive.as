package game.scenes.reality2.deepDive
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.Viewport;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.MovieClipHit;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.scenes.reality2.deepDive.diveSystem.Diver;
	import game.scenes.reality2.deepDive.diveSystem.DiverObstacle;
	import game.scenes.reality2.deepDive.diveSystem.DiverSystem;
	import game.scenes.reality2.shared.Contest;
	import game.scenes.reality2.shared.Contestant;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.MovieClipHitSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class DeepDive extends Contest
	{
		private var acc:Number = 150;
		private var npcNum:int = 1;
		private var obstacles:int = 0;
		private const VERTICAL_PADDING:int = 1000;
		private var verticalSpacing:Number;
		
		private var patternSegments:Array;
		
		private var path:Vector.<Point>;
		
		private var jellyContainer:MovieClip;
		
		private var looks:Vector.<LookData>;
		
		public function DeepDive()
		{
			super();
			practiceEnding = "You returned to the surface for air! Get ready to dive for real!";
			contestEnding = "You returned to the surface for air! Let's find out who won!";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/reality2/deepDive/";
			
			super.init(container);
		}
		
		override protected function contestantDataLoaded(xml:XML):void
		{
			var diver:Diver;
			var clip:MovieClip;
			var entity:Entity;
			
			MotionUtils.zeroMotion(shellApi.player);
			Spatial(player.get(Spatial)).y = sceneData.startPosition.y;
			
			addSystem(new DiverSystem());
			addSystem(new HitTestSystem());
			addSystem(new BitmapSequenceSystem());
			addSystem(new MovieClipHitSystem());
			addSystem(new HitTestSystem());
			addSystem(new HazardHitSystem());
			addSystem(new DestinationSystem());
			addSystem(new FollowTargetSystem());
			addSystem(new ThresholdSystem());
			
			// move gradient behind hit container
			var gradient:MovieClip = _hitContainer["gradient"];
			
			gradient.width = shellApi.viewportWidth;
			gradient.height = shellApi.viewportHeight;
			gradient.x = gradient.width/2;
			gradient.y = gradient.height/2;
			
			convertContainer(gradient);
			var container:MovieClip = createContainer(_hitContainer, false);
			container.addChild(gradient);
			
			jellyContainer = createContainer(_hitContainer, true);
			entity = EntityUtils.createSpatialEntity(this, jellyContainer);
			entity.add(new FollowTarget(getEntityById("interactive").get(Spatial)));
			//set up obstacles
			createObstacles();
			
			looks = new Vector.<LookData>();
			
			for(var i:int = 0; i < contestants.length; i++)
			{
				var contestant:Contestant = contestants[i];
				if(contestant.difficulty == Contestant.PLAYER)
				{
					diver = new Diver(practice?20:60);
					diver.ui = setUpUi("player", i, SkinUtils.getPlayerLook(this),npcLookApplied);
					var darkness:MovieClip = diver.ui["darkness"];
					if(darkness)
					{
						darkness.width = shellApi.viewportWidth;
						darkness.height = shellApi.viewportHeight;
						container = createContainer(jellyContainer, false);
						container.addChild(darkness);
					}
					diver.ranOutOfAir.addOnce(ranOutOfAir);
					shellApi.player.add(diver).add(new MovieClipHit());
					continue;
				}
				var npc:XML = xml.children()[contestant.index];
				contestant.id = DataUtils.getString(npc.attribute("id")[0]);
				var child:XML = npc.child("skin")[0];
				var look:LookData = new LookData( child);
				looks.push(look);
				
				entity = getEntityById("c"+npcNum);
				
				diver = new Diver(60);
				diver.ui = setUpUi("c"+npcNum, i, look);
				npcNum++;
				
				if(practice)
				{
					removeEntity(entity);
					continue;
				}
				
				// only bother with this if its not practice
				diver.ranOutOfAir.addOnce(ranOutOfAir);
				entity.add(new WaterCollider()).add(diver).add(new MovieClipHit())
					.remove(SceneInteraction);
				charGroup.addFSM(entity);
				SkinUtils.applyLook(entity, look, false, npcLookApplied);
				Sleep(entity.get(Sleep)).ignoreOffscreenSleep = true;
				followPath(entity, contestant);
			}
		}
		
		private function createContainer(ref:DisplayObjectContainer, over:Boolean):MovieClip
		{
			var container:MovieClip = new MovieClip();
			container.x = -shellApi.viewportWidth/2;
			container.y = -shellApi.viewportHeight/2;
			container.mouseChildren = container.mouseEnabled = false;
			groupContainer.addChild(container);
			DisplayUtils.moveToOverUnder(container, ref, over);
			return container;
		}
		
		private function followPath(entity:Entity, contestant:Contestant):void
		{
			var spatial:Spatial = entity.get(Spatial);
			var point:Point = path[0];
			
			var minTarget:Point = new Point(acc, acc);
			
			CharUtils.followPath(entity, path,null,false,false,minTarget);
			MotionControl(entity.get(MotionControl)).lockInput = false;
			var motionControl:CharacterMotionControl = entity.get(CharacterMotionControl);
			motionControl.allowAutoTarget = true;
			var baseVal:Number = .55;
			var variance:Number = .15;
			var percent:Number = .33;
			motionControl.diveSpeed = motionControl.diveSpeed * contestant.difficulty * percent + (Math.random() * variance + baseVal) * motionControl.diveSpeed;
			motionControl.moveXPercent = .5 - contestant.difficulty * percent + variance * Math.random();
			motionControl.viewportChanged(entity.get(Viewport));
		}
		
		private function createObstacles():void
		{
			var patterns:XML = getData("segmentPatterns.xml");
			var count:int = patterns.children().length();
			verticalSpacing = (sceneData.bounds.bottom - VERTICAL_PADDING * 2) / count;
			var clip:MovieClip;
			var pattern:XML;
			var obstacle:XML;
			if(!practice)
				path = new Vector.<Point>();
			
			var y:Number;
			var entity:Entity;
			var threshold:Threshold;
			var spatial:Spatial = player.get(Spatial);
			for(var i:int = 0; i < count; i++)
			{
				y = VERTICAL_PADDING + i * verticalSpacing / 2;
				
				pattern = patterns.children()[i];
				
				//creates an object that checks players position
				//will then create obstacles ahead of them, and
				//move up ahead further after the player by passes them
				clip = new MovieClip();
				entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				threshold = new Threshold("y",">",null);
				threshold.threshold = y - VERTICAL_PADDING;
				threshold.entered.addOnce(Command.create(createPattern, entity, pattern, y));
				entity.add(threshold).add(new FollowTarget(spatial));
				
				for(var o:int = 0; o < pattern.children().length(); o++)
				{
					obstacle = pattern.children()[o];
					var funcName:String = DataUtils.getString(obstacle.type);
					var position:Point = DataUtils.getPoint(obstacle);
					position.y += y;
					if(!practice && funcName == "AirBubble")
					{
						path.push(new Point(position.x, position.y));
					}
				}
			}
			if(practice)
				return;
			var offset:Number = (sceneData.bounds.bottom - VERTICAL_PADDING * 2) / 2;
			var pathLength:int = path.length;
			for(i = 0; i < pathLength; i++)
			{
				var p:Point = path[i];
				path.push(new Point(p.x,p.y+offset));
			}
		}
		// creates pattern
		private function createPattern(entity:Entity, pattern:XML, y:Number):void
		{
			for(var o:int = 0; o < pattern.children().length(); o++)
			{
				var obstacle:XML = pattern.children()[o];
				var clipName:String = DataUtils.getString(obstacle.clip);
				var funcName:String = DataUtils.getString(obstacle.type);
				var position:Point = DataUtils.getPoint(obstacle);
				position.y += y;
				this["create"+funcName](clipName, position);
			}
			//prepare to offset
			var threshold:Threshold = entity.get(Threshold);
			threshold.threshold = y + VERTICAL_PADDING;
			threshold.entered.addOnce(Command.create(offsetPattern, entity, pattern, y));
		}
		// offsetPattern
		private function offsetPattern(entity:Entity, pattern:XML, y:Number):void
		{
			var offset:Number = (sceneData.bounds.bottom - VERTICAL_PADDING * 2) / 2;
			y += offset;
			//prepare to create pattern again
			var threshold:Threshold = entity.get(Threshold);
			threshold.threshold = y - VERTICAL_PADDING;
			threshold.entered.addOnce(Command.create(createPattern, entity, pattern, y));
		}
		
		private function createAirBubble(id:String, position:Point):void
		{
			var bubble:Entity = getEntityById(id);
			if(bubble == null)
			{
				var clip:MovieClip = _hitContainer[id];
				clip.x = position.x;
				clip.y = position.y;
				convertContainer(clip);
				bubble = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			}
			else
			{
				var spatial:Spatial = bubble.get(Spatial);
				spatial.x = position.x;
				spatial.y = position.y;
				
				spatial = getEntityById(id+"Hit").get(Spatial);
				spatial.x = position.x;
				spatial.y = position.y;
				return;
			}
			
			TimelineUtils.convertAllClips(clip, null, this, true, 32, bubble);
			bubble.add(new Id(clip.name));
			
			var rect:Rectangle = clip.getRect(clip);
			var hitClip:MovieClip = new MovieClip();
			hitClip.mouseChildren = hitClip.mouseEnabled = false;
			hitClip.graphics.beginFill(0,0);
			hitClip.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			hitClip.graphics.endFill();
			hitClip.x = clip.x;
			hitClip.y = clip.y;
			
			rect.inflate(0,rect.height);
			var edge:Edge = new Edge(rect.x, rect.y, rect.width, rect.height);
			bubble.add(edge);
			var sleep:Sleep = new Sleep();
			sleep.useEdgeForBounds = true;
			sleep.ignoreOffscreenSleep = true;
			bubble.add(sleep);
			bubble.sleeping = false;
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, hitClip, _hitContainer);
			entity.add(new MovieClipHit()).add(new HitTest(onHitBubble))
				.add( new EntityIdList()).add(new DiverObstacle(2)).add(new Id(clip.name+"Hit"));
		}
		
		private function onHitBubble(hit:Entity, entityId:String):void
		{
			if(!EntityUtils.getDisplay(hit).visible)
				return;
			
			var entity:Entity = getEntityById(entityId);
			var diver:Diver = entity.get(Diver);
			
			if(diver == null || diver.air == 0)
				return;
			
			var hitId:String = Id(hit.get(Id)).id;
			var bubble:Entity = getEntityById(hitId.substr(0,hitId.length-3));
			var time:Timeline = bubble.get(Timeline);
			time.gotoAndPlay("hit");
			// after bubble animation finishes delay the bubble from respawning
			time.handleLabel("ending",Command.create(SceneUtil.delay,this, 2, 
				Command.create(reviveBubble, bubble, hit)));
			
			modifyDiver(entity, hit.get(DiverObstacle));
			EntityUtils.visible(hit, false);
		}
		
		private function reviveBubble(bubble:Entity, hit:Entity):void
		{
			Timeline(bubble.get(Timeline)).gotoAndPlay("idle");
			EntityUtils.visible(hit);
		}
		
		private function createJelly(id:String, position:Point):void
		{
			var jelly:Entity = getEntityById(id);
			if(jelly == null)
			{
				var clip:MovieClip = _hitContainer[id];
				clip.x = position.x;
				clip.y = position.y;
				convertContainer(clip);
				jelly = EntityUtils.createSpatialEntity(this, clip, jellyContainer);
			}
			else
			{
				var spatial:Spatial = jelly.get(Spatial);
				spatial.x = position.x;
				spatial.y = position.y;
				
				spatial = getEntityById(id+"Hit").get(Spatial);
				spatial.x = position.x;
				spatial.y = position.y;
				return;
			}
			
			TimelineUtils.convertAllClips(clip, null, this, true, 32, jelly);
			jelly.add(new Id(clip.name));
			
			var rect:Rectangle = clip.getRect(clip);
			rect.inflate(-50,-20);
			var hitClip:MovieClip = clip["hit"];
			if(hitClip == null)
			{
				hitClip.graphics.beginFill(0,0);
				hitClip.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
				hitClip.graphics.endFill();
			}
			_hitContainer.addChild(hitClip);
			hitClip.x = clip.x;
			hitClip.y = clip.y;
			hitClip.mouseChildren = hitClip.mouseEnabled = false;
			
			rect.inflate(0,rect.height);
			var edge:Edge = new Edge(rect.x, rect.y, rect.width, rect.height);
			jelly.add(edge);
			var sleep:Sleep = new Sleep();
			sleep.useEdgeForBounds = true;
			jelly.add(sleep);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, hitClip);
			entity.add(new MovieClipHit()).add(new HitTest(onHitJelly))
				.add( new EntityIdList()).add(new Id(clip.name+"Hit"))
				.add(new DiverObstacle(-2, new Point(-1, -500)));
		}
		
		private function onHitJelly(hit:Entity, entityId:String):void
		{
			var entity:Entity = getEntityById(entityId);
			var diver:Diver = entity.get(Diver);
			
			if(diver == null || diver.air == 0 || entity.get(Motion) == null)
				return;
			
			var hitId:String = Id(hit.get(Id)).id;
			var jelly:Entity = getEntityById(hitId.substr(0,hitId.length-3));
			Timeline(jelly.get(Timeline)).gotoAndPlay("hit");
			
			modifyDiver(entity, hit.get(DiverObstacle));
			CharUtils.lockControls(entity, true, false);
			CharUtils.setState(entity,CharacterState.HURT);
			
			SceneUtil.delay(this, 1, Command.create(SceneUtil.zeroRotation,entity));
		}
		
		private function modifyDiver(racer:Entity, obstacle:DiverObstacle):void
		{
			var motion:Motion = racer.get(Motion);
			var diver:Diver = racer.get(Diver);
			if(motion && diver.air > 0)
			{
				if(obstacle.motionModifier != null)
					motion.velocity = new Point(motion.velocity.x * obstacle.motionModifier.x,obstacle.motionModifier.y);
				
				diver.air += obstacle.airModifier;
			}
		}
		
		private function ranOutOfAir(entity:Entity):void
		{
			if(entity == shellApi.player)
			{
				trace("you lose");
				var spatial:Spatial = entity.get(Spatial);
				SceneUtil.setCameraPoint(this, spatial.x, spatial.y);
				SceneUtil.lockInput(this);
				SceneUtil.delay(this, 3, gameOver);
				updatePlacements();
			}
			else
			{
				trace(Id(entity.get(Id)).id + " lost");
			}
			// swim to surface
			CharUtils.setState(entity,CharacterState.HURT);
			
			SceneUtil.delay(this, 1, Command.create(swimToSurface,entity));
		}
		
		private function updatePlacements():void
		{
			var diver:Diver = shellApi.player.get(Diver);
			var participant:Contestant = participants[0];
			participant.place = diver.place;
			for(var i:int = 1; i < participants.length; i++)
			{
				participant = participants[i];
				diver = getEntityById("c"+i).get(Diver);
				participant.place = diver.place;
			}
		}
		
		private function swimToSurface(entity:Entity):void
		{
			SceneUtil.delay(this, 1, Command.create(SceneUtil.zeroRotation,entity));
			CharUtils.moveToTarget(entity, shellApi.viewportWidth/2, 0);
		}
		
		private function npcLookApplied(entity:Entity):void
		{
			// for some reason mouths were all getting set to 1
			// so resetting them back to their original mouths
			var id:String = entity.get(Id).id;
			var look:LookData;
			if(id.indexOf("player") > -1)
			{
				var playerLook:PlayerLook = shellApi.profileManager.active.look;
				look = new LookConverter().lookDataFromPlayerLook(playerLook);
			}
			else
			{
				var index:int = DataUtils.getNumber(id.substr(1));
				look = looks[index-1];
			}
			var currentMouth:String = look.getValue(SkinUtils.MOUTH);
			SkinUtils.setSkinPart(entity, SkinUtils.MOUTH, currentMouth);
			npcNum--;
			if(npcNum <= 0 || practice)
			{
				contestantsPrepared();
			}
		}
		
		override protected function gameOver(...args):void
		{
			SceneUtil.lockInput(this, false);
			super.gameOver();
		}
	}
}