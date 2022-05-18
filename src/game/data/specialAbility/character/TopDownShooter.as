package game.data.specialAbility.character
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Timer;
	import game.components.entity.Sleep;
	import game.components.entity.collider.RaceCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.MovieClipHit;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.ads.StarShooterGame;
	import game.scene.template.ads.TopDownBitmapGame;
	import game.scene.template.ads.TopDownRaceGame;
	import game.scene.template.ads.shared.ShooterMechanics.Bullet;
	import game.scene.template.ads.shared.ShooterMechanics.BulletNode;
	import game.scene.template.ads.shared.ShooterMechanics.Shooter;
	import game.scenes.custom.StarShooterSystem.EnemyAi;
	import game.scenes.custom.questGame.QuestGame;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	
	public class TopDownShooter extends SpecialAbility
	{
		private var shooter:Shooter;
		public var _speed:Number = 1800;
		public var _axis:String = "x";
		public var _offsetX:Number = 0;
		public var _offsetY:Number = 0;
		public var _bulletRotation:Number = 0;
		public var _fireRate:Number = .5;
		public var _targetPrefix:String;
		public var _bulletAsset:String;
		public var _shootSound:String;
		public var _followMultiply:Number = 0.3;
		
		private var timer:Number =-1;
		private var nodeList:NodeList;
		private var waitDelay:Number = 0.05;
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(shooter == null)
			{
				trace("init shooter");
				shooter = new Shooter(_bulletAsset, EntityUtils.getDisplayObject(node.entity).parent);
				trace("is display null?");
				shooter.speed = _speed;
				shooter.axis = _axis;
				shooter.offset = new Point(_offsetX, _offsetY);
				shooter.bulletRotation = _bulletRotation;
				shooter.fireRate = _fireRate;
				shooter.targetPrefix = _targetPrefix;

				loadAsset(_bulletAsset, Command.create(loadComplete, node));
				
				nodeList = systemManager.getNodeList( BulletNode );
			}
			else
			{
				shoot(node);
			}
		}
		
		private function shoot(node:SpecialAbilityNode):void
		{
			if(!(shooter.bulletAsset is DisplayObjectContainer) || timer > 0)
			{
				return;
			}
			timer = shooter.fireRate;
			setActive(true);
			
			if(DataUtils.validString(_shootSound))
				AudioUtils.play(node.owning.group, SoundManager.EFFECTS_PATH+_shootSound);
			
			var owning:DisplayGroup = node.owning.group as DisplayGroup;
			
			var spatial:Spatial;
			var shooterSpatial:Spatial = entity.get(Spatial);
			var disp:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			var bulletEntity:Entity;
			if(shooter.pool.length > 0)
			{
				bulletEntity = shooter.pool.pop();
				EntityUtils.setSleep(bulletEntity, false);
			}
			else
			{
				var bulletSprite:Sprite = owning.createBitmapSprite(shooter.bulletAsset,1,null,true,0,null,false);
				bulletEntity = EntityUtils.createMovingEntity(owning, bulletSprite, shooter.bulletContainer);
				bulletEntity.add(new Bullet(shooter)).add(new Sleep());
				
				// move bullet below ship
				var shipClip:DisplayObject = entity.get(Display).displayObject;
				var shipIndex:int = shipClip.parent.getChildIndex(shipClip);
				shipClip.parent.setChildIndex(bulletEntity.get(Display).displayObject, shipIndex);

				if(DataUtils.validString(shooter.targetPrefix))
				{
					bulletEntity.add(new HitTest(onHitTarget)).add(new EntityIdList()).add(new MovieClipHit());
				}
			}
			/*
			// add timer to bullet
			var bulletTimer:game.components.Timer = new game.components.Timer();
			var te:TimedEvent = new TimedEvent(waitDelay, .5, Command.create(bulletActive, bulletEntity));
			bulletTimer.addTimedEvent(te, true);
			bulletEntity.add(bulletTimer);
			
			// make bullet inactive until timer elapses
			// also make sure it is inactive before waking up again
			bulletEntity.get(Bullet).isActive = false;
				*/
			var point:Point = new Point(shooterSpatial.x + shooter.offset.x * shooterSpatial.scale, 
				shooterSpatial.y + shooter.offset.y * shooterSpatial.scale);
			
			// this offsets the bullet to anticipate the follow target movement
			var followOffsetX:Number = 0;
			var followOffsetY:Number = 0;
			if (entity.has(FollowTarget))
			{
				var inputSpatial:Spatial = shellApi.inputEntity.get( Spatial );
				followOffsetX = (inputSpatial.x - shooterSpatial.x) * _followMultiply;
				followOffsetY = (inputSpatial.y - shooterSpatial.y) * _followMultiply;
			}
			
			spatial = bulletEntity.get(Spatial);
			spatial.x = point.x + followOffsetX;
			spatial.y = point.y + followOffsetY;
			spatial.rotation = 0;
			var motion:Motion = bulletEntity.get(Motion);
			
			MotionUtils.zeroMotion(bulletEntity);
			
			if(shooter.axis.toLowerCase() == "x")
			{
				motion.velocity = new Point(shooter.speed, 0);
			}
			else if(shooter.axis.toLowerCase() == "y")
			{
				motion.velocity = new Point(0,-shooter.speed);
			}
			else
			{
				var target:Spatial = shellApi.inputEntity.get(Spatial);
				var radians:Number = Math.atan2(target.y - point.y, target.x - point.x) - Math.PI /4;
				motion.velocity = new Point(Math.cos(radians) * shooter.speed, -Math.sin(radians) * shooter.speed);
				spatial.rotation = radians * 180/Math.PI;
			}
			spatial.rotation += shooter.bulletRotation;
		}
		
		private function bulletActive(entity:Entity):void
		{
			//trace("bullet is now active");
			entity.get(Bullet).isActive = true;
			entity.remove(game.components.Timer);
		}
		
		private function onHitTarget(entity:Entity, id:String):void
		{
			var bullet:Bullet = entity.get(Bullet);
			
			if (!bullet.isActive)
			{
				//trace("bullet is NOT active yet");
				return;
			}
			trace("y pos: " + entity.get(Spatial).y);
			if(id.indexOf(bullet.shooter.targetPrefix)>=0)
			{
				var hit:Entity = entity.group.getEntityById(id);
				var collider:RaceCollider = hit.get(RaceCollider);
				var enemy:EnemyAi = hit.get(EnemyAi);
				// don't hit if inactive
				if (collider == null || collider.inactive)
				{
					if(enemy == null || !enemy.active)
						return;
				}
				
				handleFeedback(entity, hit);
			}
		}
		
		private function handleFeedback(entity:Entity, hit:Entity):void
		{
			AudioUtils.play(entity.group, SoundManager.EFFECTS_PATH+"explosion_01.mp3");
			EntityUtils.setSleep(entity, true);
			var ai:EnemyAi = hit.get(EnemyAi);
			var timeline:Timeline = hit.get(Timeline);
			if(ai)
			{
				ai.currentHealth--;
				trace("hp: "+ai.currentHealth);
				if(ai.currentHealth > 0)
				{
					return;
				}
				if(ai.currentHealth == 0) {
					handleEnemyHit(hit,timeline);
				}
			} 
			else {
 				handleEnemyHit(hit,timeline);
			}
			
			
		}
		private function handleEnemyHit(hit:Entity,timeline:Timeline):void
		{
			if(timeline != null)
			{
				timeline.gotoAndPlay("shot");
				timeline.handleLabel("shotEnd",Command.create(hideObstacle, hit));
			}
			else
			{
				hideObstacle(hit);
			}
		}
		private function hideObstacle(hit:Entity):void
		{
			var collider:RaceCollider = hit.get(RaceCollider);
			var enemy:EnemyAi = hit.get(EnemyAi);
			Spatial(hit.get(Spatial)).y = 1000;
			EntityUtils.setSleep(hit,true);
			// try to sent points to top down race game
			if (entity.group is QuestGame)
			{
				if(collider)
				{
					// make inactive so you can't hit with player vehicle or hit again
					collider.inactive = true;
					if (QuestGame(entity.group).gameClass is TopDownBitmapGame)
					{
						TopDownBitmapGame(QuestGame(entity.group).gameClass).gotPoints(collider.points);
					}
					else if (QuestGame(entity.group).gameClass is TopDownRaceGame)
					{
						TopDownRaceGame(QuestGame(entity.group).gameClass).gotPoints(collider.points);
					}
				}
				else if(enemy)
				{
					trace("shot enemy");
					StarShooterGame(QuestGame(entity.group).gameClass).updateScore(enemy.points);
				}
			}
		}
		
		private function loadComplete(clip:MovieClip, node:SpecialAbilityNode):void
		{
			if(clip == null)
			{
				trace("bullet not found");
				return;
			}
			
			shooter.bulletAsset = clip;
			
			shoot(node);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(timer >= 0)
				timer -= time;
			
			var allBulletsInActive:Boolean = true;
			for( var bullet : BulletNode = nodeList.head; bullet; bullet = bullet.next )
			{
				if(!bullet.sleep.sleeping)
					allBulletsInActive = false;
				if(bullet.sleep.sleeping && bullet.bullet.shooter.pool.indexOf(bullet.entity) == -1)
				{
					bullet.bullet.shooter.pool.push(bullet.entity);
					var entityIdList:EntityIdList = bullet.entity.get(EntityIdList);
					entityIdList.entities = new Vector.<String>();
				}
			}
			/*
			if(allBulletsInActive && timer < 0)
				setActive(false);
			*/
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			setActive(false);
		}
	}
}