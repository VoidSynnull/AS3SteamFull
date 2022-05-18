package game.scenes.custom.StarShooterSystem
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.FollowClipInTimeline;
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.systems.GameSystem;
	import game.util.BitmapUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	
	public class StarShooterSystem extends GameSystem
	{
		private var player:StarShooter;
		private var enemyTarget:Spatial;
		private var aiNodes:NodeList;
		private var poolNodes:NodeList;
		private static var idCount:int = 0;
		private const BITMAP:String = "bitmap";
		private const AI:String = "ai";
		
		public function StarShooterSystem(playerEntity:Entity)
		{
			player = playerEntity.get(StarShooter);
			enemyTarget = playerEntity.get(Spatial);
			super(PatternNode, updateNode);
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			aiNodes = systemManager.getNodeList(EnemyAiNode);
			poolNodes = systemManager.getNodeList(PoolerNode);
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			aiNodes = null;
			poolNodes = null;
			systemManager.releaseNodeList(EnemyAiNode);
			systemManager.releaseNodeList(PoolerNode);
			super.removeFromEngine(systemManager);
		}
		
		override public function update(time:Number):void
		{
			if(player == null)
				return;
			
			if(player.playing)
			{
				player.progressTime += time;
				if(player.hud)
				{
					if (player.alignment == "vertical")
						player.hud.scaleY = player.progressTime / player.endTime;
					else
						player.hud.scaleX = player.progressTime / player.endTime;
				}
				
				if(player.progressTime > player.endTime)
				{
					player.done.dispatch();
					return;
				}
				else
				{
					for(var timeStamp:Number in player.encounters)
					{
						if(player.progressTime > timeStamp && timeStamp > player.currentPatterTime)
						{
							player.currentPatterTime = timeStamp;
							var entity:Entity = player.encounters[timeStamp];
							var pattern:EnemyPattern = entity.get(EnemyPattern);
							if(pattern)
								pattern.init = true;
							else  
								Timeline(entity.get(Timeline)).play();
						}
					}
				}
			}
			
			super.update(time);
			
			for(var aiNode:EnemyAiNode = aiNodes.head; aiNode; aiNode = aiNode.next)
			{
				updateEnemies(aiNode, time);
			}
			
			for(var poolNode:PoolerNode = poolNodes.head; poolNode; poolNode = poolNode.next)
			{
				updatePool(poolNode, time);
			}
		}
		
		private function updatePool(node:PoolerNode, time:Number):void
		{
			if(node.entity.sleeping)
			{
				if(!node.pool.isPooled)
				{
					player.poolObject(node.pool.type, node.entity);
					node.pool.isPooled = true;
				}
			}
			else
			{
				if(node.pool.isPooled)
				{
					node.pool.isPooled = false;
				}
			}
		}
		
		private function updateNode(node:PatternNode, time:Number):void
		{
			var i:int
			var entity:Entity;
			if(!player.playing)
			{
				for each(entity in node.children.children)
				{
					if(entity != null)
					{
						entity.sleeping = true;
						entity.remove(Parent);
					}
				}
				node.children.children = new Vector.<Entity>();
				// pool and return
				return;
			}
			if(node.pattern.active)
			{
				var allChildrenDown:Boolean = true;
				for(i = 0; i < node.children.children.length; i++)
				{
					if(!node.children.children[i].sleeping)
					{
						allChildrenDown = false;
						break;
					}
				}
				if(allChildrenDown || !node.timeline.playing)
				{
					node.pattern.active = false;
					if(allChildrenDown)
					{
						node.pattern.cleared.dispatch(node.pattern.points);
					}
					else
					{
						for(i = 0; i < node.children.children.length; i++)
						{
							node.children.children[i].sleeping = true;
						}
					}
				}
			}
			else if(node.pattern.init)
			{
				node.pattern.init = false;
				node.pattern.active = true;
				node.timeline.labelReached.removeAll();
				node.timeline.reverse = false;
				
				// spawn and play pattern animation
				for each(var clip:MovieClip in node.display.displayObject)
				{
					var id:String = clip.name.split("_")[0];
					entity = player.getPooledObject(id);
					var ai:EnemyAi;
					if(entity == null)
					{
						var sequence:BitmapSequence = player.getPooledObject(id+BITMAP, true);
						var ref:MovieClip = node.display.container[id];
						if(sequence == null)
						{
							sequence = BitmapTimelineCreator.createSequence(ref);
							player.poolObject(id+BITMAP, sequence);
						}
						var sprite:Sprite = new Sprite();
						entity = EntityUtils.createSpatialEntity(node.entity.group, sprite, node.display.container);
						BitmapTimelineCreator.convertToBitmapTimeline(entity, ref, true, sequence, 1, 32, false);
						entity.add(new FollowClipInTimeline(clip, null, node.spatial));
						entity.add(new Id(id+"_"+idCount++));
						entity.managedSleep = true;
						ai = player.getPooledObject(id+AI, true);
						ai = ai.duplicate();
						var hit:MovieClipHit = new MovieClipHit();
						var hitClip:MovieClip = ref["hit"];
						if(hitClip)
						{
							var hitContainer:Sprite = new Sprite();
							sprite.addChild(hitContainer);
							var rect:Rectangle = hitClip.getRect(ref);
							hitContainer.graphics.beginFill(0,1);
							hitContainer.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
							hitContainer.graphics.endFill();
							hit.hitDisplay = hitContainer;
						}
						entity.add(ai).add(hit).add(new Pooler(id));
					}
					else
					{
						var follow:FollowClipInTimeline = entity.get(FollowClipInTimeline);
						follow.clip = clip;
						follow.parent = node.spatial;
					}
					ai = entity.get(EnemyAi);
					ai.fireCommand = clip.name;
					ai.currentHealth = ai.health;
					ai.fire = false;
					node.timeline.labelReached.add(Command.create(ai.commandFire, node.timeline));
					EntityUtils.setSleep(entity, false);
					EntityUtils.addParentChild(entity, node.entity);
					Timeline(entity.get(Timeline)).gotoAndPlay(0);
				}
				node.timeline.playing = true;
				node.timeline.gotoAndPlay(0);
			}
		}
		
		private function updateEnemies(aiNode:EnemyAiNode, time:Number):void
		{
			// TODO Auto Generated method stub
			if(aiNode.enemyAi.active)
			{
				if(aiNode.entity.sleeping)
				{
					aiNode.enemyAi.active = false;
				}
				else
				{
					switch(aiNode.enemyAi.face)
					{
						case EnemyAi.FORWARD:
						{
							// look from where i was to where i am
							if(aiNode.enemyAi.p2)
							{
								var deltaX:Number = aiNode.spatial.x - aiNode.enemyAi.p2.x;
								var deltaY:Number = aiNode.spatial.y - aiNode.enemyAi.p2.y;
								if(deltaX != 0 && deltaY != 0)
								{
									aiNode.spatial.rotation = Math.atan2(deltaY, deltaX) * 180 / Math.PI;
								}
							}
							aiNode.enemyAi.p2 = new Point(aiNode.spatial.x, aiNode.spatial.y);
							break;
						}
						case EnemyAi.PLAYER:
						{
							// look from where i am to where the player is
							if(aiNode.enemyAi.p2)
							{
								aiNode.spatial.rotation = Math.atan2(aiNode.enemyAi.p2.y - aiNode.spatial.y,
									aiNode.enemyAi.p2.x - aiNode.spatial.x) * 180 / Math.PI;
							}
							aiNode.enemyAi.p2 = new Point(enemyTarget.x, enemyTarget.y);
							break;
						}
						default:
						{
							aiNode.spatial.rotation = 90;
							break;
						}
					}
					if(aiNode.enemyAi.fire)
					{
						aiNode.enemyAi.fire = false;
						var id:String = aiNode.enemyAi.ammoType;
						var entity:Entity = player.getPooledObject(id);
						if(entity == null)
						{
							var bm:BitmapData = player.getPooledObject(id+BITMAP, true);
							var ref:MovieClip = aiNode.display.container[id];
							if(bm == null)
							{
								bm = BitmapUtils.createBitmapData(ref);
								player.poolObject(id+BITMAP, bm);
							}
							var sprite:Sprite = BitmapUtils.createBitmapSprite(ref, 1, null, true, 0, bm);
							sprite.rotation = aiNode.spatial.rotation;
							entity = EntityUtils.createMovingEntity(aiNode.entity.group, 
								sprite, aiNode.display.container).add(new Sleep())
								.add(new MovieClipHit()).add(new Id(id+"_"+idCount++))
								.add(new Pooler(id));
						}
						var motion:Motion = entity.get(Motion);
						var rad:Number = aiNode.spatial.rotation * Math.PI / 180;
						motion.velocity = new Point(Math.cos(rad) * aiNode.enemyAi.projectileSpeed, Math.sin(rad) * aiNode.enemyAi.projectileSpeed);
						
						var spatial:Spatial = entity.get(Spatial);
						spatial.x = aiNode.spatial.x + Math.cos(rad) * aiNode.enemyAi.offset
						spatial.y = aiNode.spatial.y + Math.sin(rad) * aiNode.enemyAi.offset
						EntityUtils.setSleep(entity, false);
					}
				}
			}
			else if(!aiNode.entity.sleeping)
			{
				aiNode.enemyAi.active = true;
			}
		}
	}
}