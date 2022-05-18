package game.scenes.shrink.shared.groups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Read;
	import game.scenes.shrink.shared.Systems.CarrySystem.Carry;
	import game.scenes.shrink.shared.Systems.CarrySystem.CarryNode;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	
	import org.osflash.signals.Signal;
	
	public class CarryGroup extends Group
	{
		public static const GROUP_ID:String = "carryGroup";
		
		public var pickUpDropItem:Signal;
		
		public function CarryGroup()
		{
			id = GROUP_ID;
			super();
		}
		
		public function createCarryEntity(group:Group, asset:MovieClip, container:DisplayObjectContainer):Entity
		{
			var entity:Entity = EntityUtils.createMovingEntity(group, asset, container);
			
			var edge:Edge = new Edge();
			edge.unscaled = asset.getRect(asset);
			
			entity.add(new PlatformCollider()).add(new BitmapCollider()).add(new CurrentHit())
				.add(edge).add(new MotionBounds(Scene(group).sceneData.bounds))
				.add(new SceneInteraction()).add(new Carry()).remove(Sleep);
			
			var interaction:Interaction = InteractionCreator.addToEntity(entity, ["click"]);
			interaction.click.add(clickItem);
			ToolTipCreator.addToEntity(entity);
			
			return entity;
		}
		
		public function makeEntityCarryable(group:Group, entity:Entity):void
		{
			if(entity.get(Motion) == null)
				entity.add(new Motion());
			var edge:Edge = entity.get(Edge);
			if(edge == null)
			{
				edge = new Edge();
				var displayObject:DisplayObject = EntityUtils.getDisplayObject(entity);
				edge.unscaled = displayObject.getBounds(displayObject);
				entity.add(edge);
			}
			
			if(entity.get(SceneInteraction) == null)
				entity.add(new SceneInteraction());
			
			var interaction:Interaction = entity.get(Interaction);
			if(interaction == null)
			{
				interaction = InteractionCreator.addToEntity(entity, ["click"]);
				ToolTipCreator.addToEntity(entity);
			}
			
			interaction.click.add(clickItem);
			
			entity.add(new PlatformCollider()).add(new BitmapCollider()).add(new CurrentHit())
				.add(new MotionBounds(Scene(group).sceneData.bounds)).add(new Carry()).remove(Sleep);
		}
		
		private function clickItem(entity:Entity):void
		{
			var node:CarryNode = createNodeFromEntity(entity);
			
			if(node.carry.holding)
				dropItem(entity, node.carry.carrier, node);
			else
				node.sceneInteraction.reached.addOnce(Command.create(pickUpItem, node));
		}
		
		public function pickUpItem(char:Entity, item:Entity, node:CarryNode = null):void
		{
			if(node == null)
			{
				node = createNodeFromEntity(item);
			}
			if(node.carry.holding)
				return;
			
			node.spatial.scale /= Spatial(char.get(Spatial)).scale;
			var hand:Entity = CharUtils.getPart(char, CharUtils.HAND_FRONT);
			node.display.setContainer(Display(hand.get(Display)).displayObject);
			MotionUtils.zeroMotion(item);
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim(char, 1);
			if(rigAnim == null)
			{
				var animationSlot:Entity = AnimationSlotCreator.create(char);
				rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
			}
			rigAnim.next = Read;
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK);
			
			hand.get(Display).displayObject.mouseChildren = true;
			char.get(Display).displayObject.mouseChildren = true;
			
			node.spatial.x = node.spatial.y = 0;
			
			node.carry.carrier = char;
			
			node.carry.pickUpDropItem.dispatch(item, true);
		}
		
		public function dropItem(item:Entity, char:Entity, node:CarryNode = null):void
		{
			if(node == null)
			{
				node = createNodeFromEntity(item);
			}
			
			if(!node.carry.holding)
				return;
			
			var container:DisplayObjectContainer = Display(char.get(Display)).container;
			
			node.display.setContainer(container);
			var charSpatial:Spatial = char.get(Spatial);
			node.spatial.scale *= charSpatial.scale;
			
			var handDisplay:DisplayObject = EntityUtils.getDisplayObject(CharUtils.getPart(char, CharUtils.HAND_FRONT));
			var newPoint:Point = DisplayUtils.localToLocal( handDisplay.parent, container);
			
			node.spatial.x = newPoint.x;
			node.spatial.y = newPoint.y;
			
			node.motion.acceleration = new Point(0, MotionUtils.GRAVITY);
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim(char, 1);
			if(rigAnim != null)
			{
				rigAnim.manualEnd = true;
			}
			
			node.carry.carrier = null;
			node.carry.pickUpDropItem.dispatch(item, false);
		}
		
		private function createNodeFromEntity(item:Entity):CarryNode
		{
			var node:CarryNode = new CarryNode();
			node.carry = item.get(Carry);
			node.display = item.get(Display);
			node.entity = item;
			node.interaction = item.get(Interaction);
			node.sceneInteraction = item.get(SceneInteraction);
			node.motion = item.get(Motion);
			node.spatial = item.get(Spatial);
			return node;
		}
	}
}