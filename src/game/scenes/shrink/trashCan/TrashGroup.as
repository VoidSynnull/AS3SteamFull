package game.scenes.shrink.trashCan
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Linear;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.StretchSquash;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Push;
	import game.scene.template.CollisionGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.shrink.trashCan.trash.Trash;
	import game.scenes.shrink.trashCan.trash.TrashSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.WaveMotionSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class TrashGroup extends Group
	{
		private var scene:PlatformerGameScene;
		private var container:MovieClip;
		
		private var playerPosition:Spatial;
		
		private var target:Entity;
		private var left:Entity;
		private var right:Entity;
		private var block:Entity = null;
		private var collisionGroup:CollisionGroup;
		
		public function TrashGroup(container:DisplayObjectContainer, scene:PlatformerGameScene)
		{
			this.scene = scene;
			
			playerPosition = scene.player.get(Spatial);
			this.container = container as MovieClip;
			createArrows();
			
			setUpBlocks(container["blocks"]);
			
			collisionGroup = scene.getGroupById(CollisionGroup.GROUP_ID) as CollisionGroup;
			
			var trashSystem:TrashSystem = new TrashSystem();
			trashSystem.squash.addOnce(squashPlayer);
			
			scene.addSystem(trashSystem);
			scene.addSystem(new WaveMotionSystem());
			scene.addSystem(new HitTheDeckSystem());
		}
		
		private function squashPlayer(trash:Entity, player:Entity):void
		{
			SceneUtil.lockInput(this);
			var morph:StretchSquash = MotionUtils.addStretchSquash( player, this ); 
			morph.inverseRate = .5;
			morph.scalePercent = .2;
			morph.duration = 1;
			morph.transition = Bounce.easeOut;
			morph.squash();
			morph.complete.addOnce(restart);
		}
		
		private function restart(...args):void
		{
			shellApi.loadScene( TrashCan, 550, 100, "right", 1);
		}
		
		private function createArrows():void
		{
			target = EntityUtils.createSpatialEntity(scene, new MovieClip(), container);
			EntityUtils.visible(target, false);
			Display(target.get(Display)).moveToBack();
			target.add(new FollowTarget(playerPosition));
			var asset:MovieClip = scene.getAsset(ARROW);
			var data:BitmapData = BitmapUtils.createBitmapData(asset);
			for(var i:int = 0; i < 2; i++)
			{
				arrowLoaded(asset, data);
			}
		}
		
		private var offsetX:Number = 100;
		
		private var pushDistance:Number = 150;
		
		private function arrowLoaded(asset:MovieClip, data:BitmapData):void
		{
			var sprite:Sprite = BitmapUtils.createBitmapSprite(asset, 1, null, true, 0, data);
			var direction:int = 1;
			
			if(left == null)
				direction = -1;
			
			sprite.x = offsetX * direction;
			
			var arrow:Entity = EntityUtils.createSpatialEntity(scene, sprite, EntityUtils.getDisplayObject(target));
			arrow.add(new Sleep());
			Spatial(arrow.get(Spatial)).scaleX = direction;
			
			var interaction:Interaction = InteractionCreator.addToEntity(arrow, ["click"], sprite);
			interaction.click.add(Command.create(clickArrow, direction));
			
			if(left == null)
				left = arrow;
			else
				right = arrow;
		}
		
		private function clickArrow(arrow:Entity, direction:int):void
		{
			if(block == null)
				return;
			var spatial:Spatial = block.get(Spatial);
			
			var difference:Number = playerPosition.x - spatial.x;
			
			if(difference < 0 && direction < 0 || difference > 0 && direction > 0)
				CharUtils.setAnim(scene.player, Pull);
			else
				CharUtils.setAnim(scene.player, Push);
			
			CharUtils.setDirection(scene.player, difference < 0);
			
			hideArrows();
			
			SceneUtil.lockInput(scene);
			
			shellApi.triggerEvent("move_trash");
			
			TweenUtils.entityTo(block, Spatial, 1, {x:spatial.x + pushDistance * direction, 
				ease:Linear.easeNone, onComplete:Command.create(SceneUtil.lockInput, scene, false)});
			
			TweenUtils.entityTo(scene.player, Spatial, 1, {x:spatial.x + pushDistance * direction + difference, 
				ease:Linear.easeNone, onComplete:returnControls});
		}
		
		private function hideArrows(...args):void
		{
			EntityUtils.visible(target, false);
			ToolTipCreator.removeFromEntity(left);
			ToolTipCreator.removeFromEntity(right);
		}
		
		private function showArrows():void
		{
			EntityUtils.visible(target, true);
			
			var color:uint;
			var show:Boolean = false;
			var scale:Number = collisionGroup.hitBitmapDataScale;
			var data:BitmapData = collisionGroup.hitBitmapData;
			var pos:Point = new Point(block.get(Spatial).x, block.get(Spatial).y);
			var offset:Point = new Point(collisionGroup.hitBitmapOffsetX, collisionGroup.hitBitmapOffsetY);
			
			var difference:Number = playerPosition.x - pos.x;
			
			//RIGHT ARROW
			var targetPos:Point = new Point(pos.x + pushDistance, pos.y);
			
			if(difference > 0)
				targetPos.x += pushDistance;// checking behind the player
			
			color = data.getPixel(targetPos.x * scale + offset.x, targetPos.y * scale + offset.y);
			targetPos = DisplayUtils.localToLocalPoint(targetPos, container, container.stage);
			show = (color == 0 && !container.hitTestPoint(targetPos.x, targetPos.y, true));// checks against bitmap hits
			
			showArrow(right, show);
			
			//LEFT ARROW
			targetPos = new Point(pos.x - pushDistance, pos.y);
			
			if(difference < 0)
				targetPos.x -= pushDistance;// checking behind the player
			
			color = data.getPixel(targetPos.x * scale + offset.x, targetPos.y * scale + offset.y);
			targetPos = DisplayUtils.localToLocalPoint(targetPos, container, container.stage);
			show = (color == 0 && !container.hitTestPoint(targetPos.x, targetPos.y, true));// checks against bitmap hits
			
			showArrow(left, show);
		}
		
		private function showArrow(arrow:Entity, show:Boolean = true):void
		{
			EntityUtils.visible(arrow, show);
			if(show)
				ToolTipCreator.addToEntity(arrow);
			else
				ToolTipCreator.removeFromEntity(arrow);
		}
		
		private function setUpBlocks(blockContainer:MovieClip):void
		{
			blockContainer.mouseChildren = true;
			blockContainer.mouseEnabled = false;
			this.container = blockContainer;
			var display:DisplayObject
			for each (display in blockContainer)
			{
				if(display.name.indexOf(PUSH) > -1)
				{
					createBlock(display as MovieClip, true);
				}
				else if(display.name.indexOf(BLOCK) > -1)
				{
					createBlock(display as MovieClip, false);
				}
			}
		}
		
		private var platformWidth:Number = 50;
		private var padding:Number = 10;
		
		private function createBlock(clip:MovieClip, push:Boolean):void
		{
			var blockName:String = clip.name;
			var sprite:Sprite = BitmapUtils.createBitmapSprite(clip);
			sprite.mouseChildren = sprite.mouseEnabled = push;
			var entity:Entity = EntityUtils.createMovingEntity(scene, sprite, container);
			
			var edge:Edge = new Edge();
			edge.unscaled = clip.getBounds(clip);
			
			container.removeChild(clip);
			
			// platform
			clip = new MovieClip();
			clip.graphics.beginFill(0, 0);
			clip.graphics.drawRect(edge.unscaled.left, -platformWidth / 2, edge.unscaled.width, platformWidth);
			sprite = BitmapUtils.createBitmapSprite(clip);
			sprite.mouseChildren = sprite.mouseEnabled = false;
			
			var platform:Entity = EntityUtils.createSpatialEntity(scene, sprite, container);
			
			var follow:FollowTarget = new FollowTarget(entity.get(Spatial));
			follow.offset = new Point(0, edge.unscaled.top + padding);			
			platform.add(new Platform()).add(follow);
			//I tried adding sleep to platforms as well, 
			//but blocks fell through platforms of the blocks below
			//when top blocks were on screen before lower blocks
			
			var data:WaveMotionData = new WaveMotionData("rotation", 0);
			var shake:WaveMotion = new WaveMotion();
			shake.add(data);
			
			if(push)
			{
				var hitTheDeck:HitTheDeck = new HitTheDeck(scene.player.get(Spatial), edge.unscaled.right * 2, false);
				hitTheDeck.coastClear.add(hideArrows);
				InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add(pushBlock);
				sceneInteraction.minTargetDelta = new Point(edge.unscaled.right + 25, 100);
				sceneInteraction.validCharStates = new <String>[CharacterState.STAND, CharacterState.WALK];
				entity.add(sceneInteraction).add(hitTheDeck);
				ToolTipCreator.addToEntity(entity);
			}
			
			entity.add(new Id(blockName)).add(new PlatformCollider()).add(new BitmapCollider())
				.add(edge).add(new CurrentHit()).add(new MotionBounds(scene.sceneData.bounds))
				.add(new SceneObjectMotion()).add(new Wall()).add(new Trash()).add(shake).add(new Sleep());
			
			if(!PlatformUtils.isMobileOS)
			{
				entity.add(new SpatialAddition());
			}
		}
		
		private function pushBlock(player:Entity, block:Entity):void
		{
			this.block = block;
			var blockSpatial:Spatial = block.get(Spatial);
			var targetSpatial:Spatial = target.get(Spatial);
			targetSpatial.x = blockSpatial.x;
			targetSpatial.y = blockSpatial.y;
			FollowTarget(target.get(FollowTarget)).target = blockSpatial;
			showArrows();
		}
		
		private function returnControls(...args):void
		{
			FSMControl(scene.player.get(FSMControl)).active = true;
			CharUtils.setState(scene.player, CharacterState.STAND);
		}
		
		private const ARROW:String = "arrow.swf";
		private const BLOCK:String = "block";
		private const PUSH:String = "push";
	}
}